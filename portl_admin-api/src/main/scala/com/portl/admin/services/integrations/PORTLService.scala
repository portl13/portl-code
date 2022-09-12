package com.portl.admin.services.integrations

import akka.Done
import akka.stream.Materializer
import akka.stream.scaladsl.{Flow, Keep, Sink, Source}
import com.portl.admin.models.internal
import com.portl.admin.models.internal._
import com.portl.admin.services.GeocodingResultsService
import com.portl.admin.services.background.BackgroundTaskService
import com.portl.commons
import com.portl.commons.models.{EventCategory, SourceIdentifier, StoredArtist, StoredEvent, StoredVenue}
import com.portl.commons.models.base.StoredPortlEntity
import com.portl.commons.services.MongoService
import com.portl.commons.serializers.Mongo.dateTimeFormat
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.json.Json.JsValueWrapper
import play.api.libs.json._
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import reactivemongo.akkastream.cursorProducer
import reactivemongo.api.{Cursor, CursorOptions, ReadConcern, ReadPreference}
import reactivemongo.api.commands.{UpdateWriteResult, WriteResult}
import reactivemongo.api.bson.BSONRegex
import reactivemongo.play.json.compat._

import scala.concurrent.{Await, ExecutionContext, Future}

class PORTLService @Inject()(@NamedDatabase("data") val reactiveMongoApi: ReactiveMongoApi,
                             geocodingService: GeocodingResultsService,
                             implicit val executionContext: ExecutionContext,
                             implicit val materializer: Materializer)
    extends MongoService {

  val VENUES = "venues"
  val ARTISTS = "artists"
  val EVENTS = "events"
  val HISTORICAL_EVENTS = "historicalEvents"

  implicit class PrioritizedEntity(self: StorablePortlEntity) {
    def priorityOrder: Seq[commons.models.EventSource] = {
      import commons.models.EventSource._
      self match {
        case a: Artist =>
          Seq(
            Meetup,
            Songkick,
            Ticketfly,
            Eventbrite,
            Ticketmaster,
            Bandsintown,
            PortlServer
          )
        case _ =>
          Seq(
            Songkick,
            Bandsintown,
            Meetup,
            Ticketfly,
            Eventbrite,
            Ticketmaster,
            PortlServer
          )
      }
    }

    def isLowerPriorityThan(o: StoredPortlEntity): Boolean = {
      priorityOrder.indexOf(self.externalId.sourceType) < priorityOrder.indexOf(o.externalId.sourceType)
    }
  }

  /**
    * Wrapper with convenience methods for storing StorablePortlEntity objects.
    *
    *   StorablePortlEntity doesn't include externalIdSet, because it won't be available when constructing a new one
    *   from a source entity. For updates, we use \$addToSet to include the externalId in the existing object's
    *   externalIdSet. For inserts, we need to initialize externalIdSet to [externalId].
    */
  implicit class UpdatableEntity(e: StorablePortlEntity) {
    def selector =
      Json.obj(
        "externalIdSet" -> Json.obj(
          "$elemMatch" -> Json
            .obj("sourceType" -> e.externalId.sourceType, "identifierOnSource" -> e.externalId.identifierOnSource)),
        "markedForDeletion" -> JsNull
      )

    def updateDocument = Json.obj(
      "$set" -> e.toJsObject,
      "$addToSet" -> Json.obj("externalIdSet" -> e.externalId)
    )

    def markAsDuplicateDocument = Json.obj(
      "$addToSet" -> Json.obj("externalIdSet" -> e.externalId)
    )

    def insertDocument = e.toJsObject ++ Json.obj("externalIdSet" -> Json.arr(e.externalId))

    lazy val loggableId = s"${e.externalId.sourceType}, ${e.externalId.identifierOnSource}"
  }

  def countEvents: Future[Long] = {
    collection(EVENTS).flatMap(_.count(None, None, 0, None, ReadConcern.Local))
  }

  def storeArtist(artist: MapsToPortlEntity[internal.Artist]): Future[Option[commons.models.StoredArtist]] = {
    val portlArtist = artist.toPortl

    for {
      matching <- findMatching[commons.models.StoredArtist](portlArtist, ARTISTS)
      existing <- if (matching.nonEmpty) Future(matching) else findDuplicateArtists(portlArtist)
      _ <- updateDuplicates(portlArtist, existing, ARTISTS, shouldMarkAsDuplicate, shouldUpdateArtist)
      _ <- if (existing.isEmpty) insertEntity(portlArtist, ARTISTS) else Future.unit
      result <- findCanonicalEntity[commons.models.StoredArtist](portlArtist, ARTISTS)
    } yield {
      if (result.isEmpty) {
        // TODO : storeX should always return a StoredX
        log.warn("storeArtist returned None for {}", portlArtist)
      }
      result
    }
  }

  /**
    * Find stored venues considered to be duplicates of the given venue.
    *
    * This is more expensive than `findMatchingVenues`.
    */
  private def findDuplicateVenues(portlVenue: internal.Venue, matchName: Boolean = true): Future[Seq[commons.models.StoredVenue]] = {
    /*
    duplicate criteria:
      POR-130: within 1000m and ci name match
      POR-814: compare names after removing punctuation and normalizing whitespace

    To accomplish both, we:
      1) use the text index to get similar names and filter on the 1000m radius
      2) remove punctuation, normalize whitespace and casing and compare in code

    TODO : not in blacklist
     */
    val EARTH_RADIUS_KILOMETERS: Double = 6371.0
    val DUPLICATE_RADIUS_KILOMETERS: Double = 1
    val locationClause: (String, JsValueWrapper) = "location" -> Json.obj(
      "$geoWithin" -> Json.obj(
        "$centerSphere" -> Json
          .arr(
            Json.arr(portlVenue.location.longitude, portlVenue.location.latitude),
            DUPLICATE_RADIUS_KILOMETERS / EARTH_RADIUS_KILOMETERS)
      )
    )
    val nameClause: (String, JsValueWrapper) = portlVenue.name match {
      case Some(name) =>
        "$text" -> Json.obj("$search" -> name)
      case _ =>
        "name" -> JsNull
    }
    val notDeletedClause: (String, JsValueWrapper) = "markedForDeletion" -> JsNull
    val query = Json.obj(nameClause, locationClause, notDeletedClause)

    def normalizeName(name: Option[String]): String = {
      name
        .map(
          _.trim
            .replaceAll("""\p{Punct}""", "")
            .replaceAll("""\s+""", " ")
            .toLowerCase)
        .getOrElse("")
    }

    val normalizedInputName = normalizeName(portlVenue.name)

    def nameMatchPredicate(venue: commons.models.StoredVenue): Boolean = {
      val inputVenue = normalizedInputName
      val otherVenue = normalizeName(venue.name)

      if (inputVenue.length < otherVenue.length) {
        val hasMatch = otherVenue.contains(inputVenue)
        if (hasMatch) {
          log.info("2) ++ NAME MATCHED inputVenue ({}) is in otherVenue ({})", inputVenue, otherVenue, "")
        } else {
          // log.info("2) -- not matched inputVenue ({}) is not in otherVenue ({})", inputVenue, otherVenue, "")
        }
        return hasMatch
      } else {
        val hasMatch = inputVenue.contains(otherVenue)
        if (hasMatch) {
          log.info("2) ++ NAME MATCHED inputVenue ({}) contains otherVenue ({})", inputVenue, otherVenue, "")
        } else {
          // log.info("2) -- not matched otherVenue ({}) is not in inputVenue ({})", otherVenue, inputVenue, "")
        }
        return hasMatch
      }
  }

    log.info("2) findDuplicateVenues query: {}", query)
    for {
      c <- collection(VENUES)
      existing <- c
        .find[JsObject, JsObject](query)
        .cursor[commons.models.StoredVenue]()
        .collect[Seq](-1, Cursor.ContOnError((_, ex: Throwable) => {
          log.error(s"error collecting venues", ex)
        }))
    //} yield existing.filter(nameMatchPredicate)
    } yield {
      if (matchName) {
        existing.filter(nameMatchPredicate)
      } else {
        existing
      }
    }
  }

  private def findDuplicateVenuesByGeocodingResult(venue: internal.Venue): Future[Seq[commons.models.StoredVenue]] = {
    for {
      geo <- geocodingService.findByExternalId(venue.externalId)
      geoMatches <- geo
        .flatMap(_.reverseGeocodingResult)
        .map(_.formattedAddress)
        .map(geocodingService.findByAddress)
        .getOrElse(Future(List.empty))
      idMatches = geoMatches
        .map(_.externalId)
        .filter(_ != venue.externalId)
      c <- collection(VENUES)
      venues <- c.findList[ByExternalIdSet, commons.models.StoredVenue](ByExternalIdSet(idMatches.toSet))
      _ = log.info(s"geocoding matches: ${venue.externalId} -> ${venues.map(_.externalId)}")
    } yield venues
  }

  private def findDuplicateArtists(portlArtist: internal.Artist): Future[Seq[commons.models.StoredArtist]] = {
    // POR-129 Duplicate criteria:
    // "In most cases, artists with the same name can be considered duplicates."
    // Case-insensitive name match.

    val textIndexSearch = Json.obj("$text" -> Json.obj("$search" -> s""""${portlArtist.name}""""))
    val anchoredCaseInsensitiveRegexSearch = Json.obj("$regex" -> s"(?i)^${portlArtist.name}$$")
    val query = Json.obj(
      "$and" -> Json.arr(
        textIndexSearch,
        Json.obj("name" -> anchoredCaseInsensitiveRegexSearch),
        Json.obj("markedForDeletion" -> JsNull)))

    for {
      c <- collection(ARTISTS)
      existing <- c
        .find[JsObject, JsObject](query, None)
        .cursor[commons.models.StoredArtist]()
        .collect[Seq](-1, Cursor.ContOnError((_, ex: Throwable) => {
          log.error(s"error collecting artists", ex)
        }))
    } yield existing
  }

  private def shouldUpdateArtist(newArtist: internal.Artist)(existingArtist: commons.models.StoredArtist): Boolean = {
    !existingArtist.externalIdSet.contains(newArtist.externalId) ||
    existingArtist.name != newArtist.name ||
    existingArtist.url != newArtist.url ||
    existingArtist.imageUrl != newArtist.imageUrl ||
    existingArtist.description != newArtist.description
  }

  def shouldUpdateLocation(newLocation: commons.models.Location, existingLocation: commons.models.Location): Boolean = {
    // We have a bunch of duplicate Songkick source venues, except with different precision on the location:
    // { "displayName" : "The Garage", "lng" : -4.26876, "lat" : 55.86615, <everything else equal> }
    // { "displayName" : "The Garage", "lng" : -4.2687564, "lat" : 55.8661471, <everything else equal> }
    // Special case this, and don't update if it's just the same location but lower precision.

    // round existingVenue.location to the precision of newVenue.location
    // if equal, then existingVenue has greater precision (or is equal) - leave it
    // e.g., old: -123.45, new: -123.4512 -> update to new
    // old: -123.45, new: -123.5 -> leave it
    // old: -123.45, new: -123.46 -> update to new
    val newLat = BigDecimal(newLocation.latitude)
    val oldLat = BigDecimal(existingLocation.latitude)
    val newLng = BigDecimal(newLocation.longitude)
    val oldLng = BigDecimal(existingLocation.longitude)

    // differs by other than just greater precision on existing
    oldLat.setScale(newLat.scale, BigDecimal.RoundingMode.HALF_UP) != newLat ||
    oldLng.setScale(newLng.scale, BigDecimal.RoundingMode.HALF_UP) != newLng
  }

  private def shouldUpdateVenue(newVenue: internal.Venue)(existingVenue: commons.models.StoredVenue): Boolean = {
    !existingVenue.externalIdSet.contains(newVenue.externalId) ||
    existingVenue.name != newVenue.name ||
    shouldUpdateLocation(newVenue.location, existingVenue.location) ||
    existingVenue.address != newVenue.address ||
    existingVenue.url != newVenue.url
  }

  def storeVenue(venue: MapsToPortlEntity[internal.Venue]): Future[Option[commons.models.StoredVenue]] = {
    val portlVenue = venue.toPortl

    for {
      matching <- findMatching[commons.models.StoredVenue](portlVenue, VENUES)
      existing <-
        if (matching.nonEmpty) Future(matching)
        else findDuplicateVenues(portlVenue, matchName=true)
          .flatMap { d =>
            findDuplicateVenuesByGeocodingResult(portlVenue)
              .map(_ ++ d)
          }
      _ <- updateDuplicates(portlVenue, existing, VENUES, shouldMarkAsDuplicate, shouldUpdateVenue)
      _ <- if (existing.isEmpty) insertEntity(portlVenue, VENUES) else Future.unit
      result <- findCanonicalEntity[commons.models.StoredVenue](portlVenue, VENUES)
    } yield result
  }

  /**
    * Find stored entities with the given entity's external id.
    */
  private def findMatching[T](portlEntity: UpdatableEntity, collectionName: String)(
      implicit reader: Reads[T]): Future[Seq[T]] = {
    for {
      c <- collection(collectionName)
      existing <- c
        .find[JsObject, JsObject](portlEntity.selector, None)
        .cursor[T]()
        .collect[Seq](-1, Cursor.ContOnError((_, ex: Throwable) => {
          log.error(s"error loading matching entities", ex)
        }))
    } yield existing
  }


  def markVenueForDeletion(venue: Venue): Future[UpdateWriteResult] = {
    val venueQuery = Json.obj(
      "externalId.sourceType" -> venue.externalId.sourceType,
      "externalId.identifierOnSource" -> venue.externalId.identifierOnSource,
    )

    val deletedAt = DateTime.now
    val deletionUpdate = Json.obj(
      "$set" -> Json.obj("markedForDeletion" -> deletedAt)
    )

    for {
      c <- collection(VENUES)
      writeResult <- c.update(true).one(venueQuery, deletionUpdate, upsert=true, multi=false)
    } yield writeResult
  }

  /*
  TODO

  Move TestObjects generation for portl-commons entities into portl-commons
   */

  /**
    * Find stored events considered to be duplicates of the given event.
    *
    * This is more expensive than `findMatchingEvents`.
    */
  private def findDuplicateEvents(portlEvent: StorableEvent): Future[Seq[commons.models.StoredEvent]] = {
    /*
    POR-128
    duplicate criteria:
    same venue starting within the same day (POR-1463)
     */
    import com.portl.commons.serializers.Mongo._

    val t1 = portlEvent.startDateTime.withTimeAtStartOfDay()
    val t2 = portlEvent.startDateTime.plusDays(1).withTimeAtStartOfDay()

    val query: JsObject = portlEvent.artist match {
      case Some(artist) => {
        Json.obj(
          "$and" -> Json.arr(
            Json.obj("artist.name" -> artist.name),
            Json.obj("localStartDate" -> portlEvent.localStartDate),
            Json.obj("markedForDeletion" -> JsNull)
          )
        )

      }
      case None => {
        val EARTH_RADIUS_KILOMETERS: Double = 6371.0
        val DUPLICATE_RADIUS_KILOMETERS: Double = 1
        val locationClause: (String, JsValueWrapper) = "venue.location" -> Json.obj(
          "$geoWithin" -> Json.obj(
            "$centerSphere" -> Json
              .arr(
                Json.arr(portlEvent.venue.location.longitude, portlEvent.venue.location.latitude),
                DUPLICATE_RADIUS_KILOMETERS / EARTH_RADIUS_KILOMETERS)
          )
        )

        Json.obj(
          "$and" -> Json.arr(
            Json.obj("venue._id" -> portlEvent.venue.id),
            //Json.obj("venue.name" -> portlEvent.venue.name),
            //Json.obj(locationClause),
            Json.obj("localStartDate" -> portlEvent.localStartDate),
            Json.obj("markedForDeletion" -> JsNull)
          )
        )
      }
    }

    log.info("2) findDuplicateEvents query: {}", query)
    for {
      c <- collection(EVENTS)
      existing <- c
        .find[JsObject, JsObject](query, None)
        .cursor[commons.models.StoredEvent]()
        .collect[Seq](-1, Cursor.ContOnError((_, ex: Throwable) => {
          log.error(s"error loading matching entities", ex)
        }))
    } yield existing
  }

  private def shouldUpdateEvent(newEvent: StorableEvent)(existingEvent: commons.models.StoredEvent): Boolean = {
    // TODO
    // update if newEvent.externalId is not in existingEvent.externalIdSet, or if any other field differs

    !existingEvent.externalIdSet.contains(newEvent.externalId) ||
    newEvent.externalId != existingEvent.externalId ||
    newEvent.title != existingEvent.title ||
    newEvent.imageUrl != existingEvent.imageUrl ||
    newEvent.description != existingEvent.description ||
    newEvent.startDateTime != existingEvent.startDateTime ||
    newEvent.endDateTime != existingEvent.endDateTime ||
    newEvent.categories != existingEvent.categories ||
    newEvent.venue != existingEvent.venue ||
    newEvent.artist != existingEvent.artist ||
    newEvent.url != existingEvent.url ||
    newEvent.ticketPurchaseUrl != existingEvent.ticketPurchaseUrl ||
    newEvent.localStartDate != existingEvent.localStartDate

    /*
    StoredEvent
    externalId: SourceIdentifier,
    externalIdSet: Set[SourceIdentifier] = Set(),
    title: String,
    imageUrl: Option[String],
    description: Option[MarkupText],
    startDateTime: DateTime,
    endDateTime: Option[DateTime],
    categories: Seq[EventCategory] = Seq(),
    venue: Option[StoredVenue],
    artist: Option[StoredArtist],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
    computedDistance: Option[Double],
    localStartDate: String,
    markedForDeletion: Option[DateTime]

    StorableEvent
    externalId: SourceIdentifier,
    title: String,
    imageUrl: Option[String],
    description: Option[MarkupText],
    startDateTime: DateTime,
    endDateTime: Option[DateTime],
    timezone: String,
    categories: Seq[EventCategory] = Seq(),
    venue: StoredVenue,
    artist: Option[StoredArtist],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
    localStartDate: String // yyyy-mm-dd
   */
  }

  /**
    * Update the given set of existing stored entities with the data from the given entity.
    *
    * Add the new entity's source identifier to the stored entities' externalIdSets.
    *
    * For stored entities with a data source of lower priority than the new entity, update the stored entities to match
    * the new entity as well.
    *
    * @param portlEntity The new entity whose data we're interested in
    * @param existing The existing matching entities to update
    * @param collectionName The name of the Mongo collection to update
    * @param shouldMarkAsDuplicate Decides whether to add a new entity's id to the stored entity's id set.
    * @param shouldUpdate Decides whether to update a stored entity with a new entity's data.
    * @tparam T Type of the storable (new) entity.
    * @tparam S Type of the existing stored entities.
    * @return Future[Unit]
    */
  private def updateDuplicates[T <: StorablePortlEntity, S <: StoredPortlEntity](
      portlEntity: T,
      existing: Seq[S],
      collectionName: String,
      shouldMarkAsDuplicate: T => S => Boolean,
      shouldUpdate: T => S => Boolean): Future[Unit] = {
    val (higherPriority, lowerPriority) = existing.partition { stored =>
      portlEntity.isLowerPriorityThan(stored)
    }

    val toMark = higherPriority.filter(shouldMarkAsDuplicate(portlEntity))
    val toUpdate = lowerPriority.filter(shouldUpdate(portlEntity))

    for {
      c <- collection(collectionName)
      _ <- {
        if (toMark.nonEmpty) {
          val higherIds = toMark.map(_.id)
          log.info(s"Dedupe $collectionName (${portlEntity.loggableId}): Mark as dupe of ($higherIds)")
          val higherSelector = Json.obj("_id" -> Json.obj("$in" -> higherIds))
          c.update(true).one(higherSelector, portlEntity.markAsDuplicateDocument, multi = true).recover {
            case e => log.error("error marking duplicates", e)
          }
        } else Future.unit
      }

      _ <- {
        if (toUpdate.nonEmpty) {
          // Example: we are processing a TM event, and we found a corresponding SK event.
          // Update the SK event to have the TM externalId (this breaks uniqueness on externalId).
          //    - Leaves multiple copies of the same event with no way to choose a canonical one
          //    - After a full aggregation run, we should no longer see new duplicates appear
          //    - TODO : In the future, go through and mark all but one for deletion
          //    - Select those not marked for deletion to choose canonical event to return from this method
          val lowerIds = toUpdate.map(_.id)
          log.info(s"Dedupe $collectionName (${portlEntity.loggableId}): Update ($lowerIds)")
          val lowerSelector = Json.obj("_id" -> Json.obj("$in" -> lowerIds))
          c.update(true).one(lowerSelector, portlEntity.updateDocument, multi = true).recover {
            case e => log.error("error updating duplicates", e)
          }
        } else Future.unit
      }
    } yield ()
  }

  /**
    * Insert the given entity. Callers should consider finding and updating any duplicates instead before calling this.
    */
  private def insertEntity(portlEntity: StorablePortlEntity, collectionName: String): Future[WriteResult] = {
    log.info(s"Insert $collectionName (${portlEntity.loggableId})")
    collection(collectionName).flatMap(_.insert(false).one(portlEntity.insertDocument))
  }

  /**
    * Find the stored entity matching the given entity, if any.
    */
  private def findCanonicalEntity[S <: StoredPortlEntity](portlEntity: StorablePortlEntity, collectionName: String)(
      implicit reads: Reads[S]): Future[Option[S]] = for {
      c <- collection(collectionName)
      result <- {
        import c.BatchCommands.AggregationFramework._
        // [7,6,4,3,1], $externalId.sourceType (e.g., Meetup -> priority: 0, Ticketmaster -> priority: 4)
        val priority = Json.obj(
          "priority" -> Json.obj("$indexOfArray" -> Json.arr(portlEntity.priorityOrder, "$externalId.sourceType")))
        val queryResult = c.aggregatorContext[S](
            Match(portlEntity.selector),
            List(AddFields(priority), Sort(Descending("priority"), Ascending("_id")), Limit(1)),
            explain = false,
            allowDiskUse = true,
            bypassDocumentValidation = false,
            readConcern = ReadConcern.Local,
            readPreference = c.db.connection.options.readPreference,
            writeConcern = c.db.connection.options.writeConcern,
            batchSize = None,
            cursorOptions = CursorOptions.empty,
            maxTime = None,
            hint = None,
            comment = None,
            collation = None
          )
          .prepared
          .cursor

        import scala.concurrent.duration._
        import reactivemongo.api.Cursor

        // https :// github.com / typesafehub / scalalogging / issues / 16
        log.info("1) The canonical entity given {} ({}) ...", portlEntity.externalId.identifierOnSource, portlEntity.externalId.sourceType, "")
        log.info("1) ... looking for match via {} ...", portlEntity.selector)

        val highestOrder = queryResult.headOption
        Await.result(highestOrder, 10 seconds)

        highestOrder.collect({
            case Some(highest) => {
              val thisId = portlEntity.externalId.identifierOnSource
              val canonId = highest.externalId.identifierOnSource
              if (thisId == canonId) {
                log.info("1) ... found ourselves, {}", thisId)
              } else {
                // https :// github.com / typesafehub / scalalogging / issues / 16
                log.info("1) !!!!! Found ourselves ({}) being a duplicate of, {}!!", thisId, canonId, "")
              }
            }
        })

        highestOrder
      }
    } yield result

  private def shouldMarkAsDuplicate(newEntity: StorablePortlEntity)(existingEntity: StoredPortlEntity): Boolean =
    !existingEntity.externalIdSet.contains(newEntity.externalId)

  def storeEvent(event: MapsToPortlEntity[internal.Event]): Future[Option[commons.models.StoredEvent]] = {
    val portlEvent = try {
      event.toPortl
    } catch {
      case e: InvalidEventException =>
        log.warn("Invalid Event", e)
        return Future(None)
    }

    for {
      venue <- this.storeVenue(portlEvent.venue)
      artist <- portlEvent.artist match {
        case Some(a) => this.storeArtist(a)
        case _       => Future(None)
      }

      // TODO : storeX should always return a StoredX
      storedVenue = venue match {
        case Some(v) => v
        case _ =>
          log.error("storeEvent returned None for venue {}", Json.toJson(portlEvent))
          venue.get
      }
      storableEvent = StorableEvent(portlEvent, storedVenue, artist)

      matching <- findMatching[commons.models.StoredEvent](storableEvent, EVENTS)
      existing <- if (matching.nonEmpty) Future(matching) else findDuplicateEvents(storableEvent)
      _ <- updateDuplicates(storableEvent, existing, EVENTS, shouldMarkAsDuplicate, shouldUpdateEvent)
      _ <- if (existing.isEmpty) insertEntity(storableEvent, EVENTS) else Future.unit
      result <- findCanonicalEntity[commons.models.StoredEvent](storableEvent, EVENTS)
    } yield result
  }

  def storeEventsSink(parallelism: Int = 1): Sink[MapsToPortlEntity[internal.Event], Future[Done]] =
    Flow[MapsToPortlEntity[internal.Event]]
      .mapAsync[Option[commons.models.StoredEvent]](parallelism)(storeEvent)
      .toMat(Sink.foreach(_ => ()))(Keep.right)

  def distinctMusicArtistNames(): Future[Set[String]] = {
    // We want to find artists who have Music events. Category information isn't available directly on the Artist, so we
    // must query the events collection.
    // Look up Music events with non-null artists. Query artist._id instead of artist to hit the index.
    val selector = Json.obj(
      "artist._id" -> Json.obj("$ne" -> JsNull),
      "categories" -> EventCategory.Music
    )

    for {
      c <- collection(EVENTS)
      result <- {
        import c.BatchCommands.AggregationFramework.{Match, Group, AddFieldToSet}

        c.aggregatorContext[NamesAggregationResult](
            Match(selector),
            List(Group(JsNull)("names" -> AddFieldToSet("artist.name"))),
            explain = false,
            allowDiskUse = true,
            bypassDocumentValidation = false,
            readConcern = ReadConcern.Local,
            readPreference = c.db.connection.options.readPreference,
            writeConcern = c.db.connection.options.writeConcern,
            batchSize = None,
            cursorOptions = CursorOptions.empty,
            maxTime = None,
            hint = None,
            comment = None,
            collation = None
          )
          .prepared
          .cursor
          .head
      }
    } yield result.names
  }

  def musicArtistsSource(): Source[internal.Artist, _] = {
    val futureSource = for {
      c <- collection(ARTISTS)
    } yield
      c.find[JsObject, JsObject](JsObject.empty, None)
        .cursor[internal.Artist](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson(event).toString, e)
        }))
    Source.fromFutureSource(futureSource)
  }

  def allEventsCount(eventName: Option[String]): Future[Long] = {
    val selector = eventName match {
      case Some(eventName) => Json.obj(
        "markedForDeletion" -> JsNull,
        "title" -> fromRegex(BSONRegex(eventName, "i"))
      )
      case None => Json.obj(
        "markedForDeletion" -> JsNull,
      )
    }

    collection(EVENTS).flatMap(c => {
      c.countS(selector)
    })
  }

  def allVenuesCount(): Future[Long] = {
    collection(VENUES).flatMap(c => {
      val selector = Json.obj(
        "markedForDeletion" -> JsNull,
        "name" -> fromRegex(BSONRegex("Wow Hall", "i"))
      )
      c.countS(selector)
    })
  }

  def allVenuesSource(venueName: Option[String]): Source[internal.Venue, _] = {
    val selector = venueName match {
      case Some(venueName) => Json.obj(
        "markedForDeletion" -> JsNull,
        "name" -> fromRegex(BSONRegex(venueName, "i"))
      )
      case None => Json.obj(
        "markedForDeletion" -> JsNull,
      )
    }

    val futureSource = for {
      c <- collection(VENUES)
    } yield {
      c.find[JsObject, JsObject](selector, None)
        .cursor[internal.Venue](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson(event).toString, e)
        }))
    }
    Source.fromFutureSource(futureSource)
  }

  private def deduplicateVenue(venue: Venue, matchName: Boolean = true): Future[Done] = {
    log.info("deduplicateVenue({}, {})", venue.name, matchName:Any)
    // find matching
    for {
      canonicalOption <- findCanonicalEntity[StoredVenue](venue, VENUES)
      matching <- findDuplicateVenues(venue, matchName=matchName)
      done <- canonicalOption.map { canonical =>
        val duplicates = matching.filter(_.id != canonical.id)
        val duplicateIds = duplicates.map(_.id)

        log.info("3) !!!!! canonical {} ({}), updating duplicates venues...",
          canonical.name, canonical.externalId.identifierOnSource, "")
        duplicates.foreach(dupe => log.info("-> 3) duplicates: {}", dupe.name))

        // update corresponding events to point at canonical venue
        val eventsQuery = Json.obj("venue._id" -> Json.obj("$in" -> duplicateIds))
        val eventsUpdate = Json.obj("$set" -> Json.obj("venue" -> canonical))

        // Mark duplicates for deletion.
        val duplicatesQuery = Json.obj("_id" -> Json.obj("$in" -> duplicateIds))
        val deletedAt = DateTime.now
        val duplicatesUpdate = Json.obj("$set" -> Json.obj("markedForDeletion" -> deletedAt))

        for {
          eventsCollection <- collection(EVENTS)
          _ <- eventsCollection.update(false).one(eventsQuery, eventsUpdate, upsert = false, multi = true)
          venuesCollection <- collection(VENUES)
          _ <- venuesCollection.update(false).one(duplicatesQuery, duplicatesUpdate, upsert = false, multi = true)
        } yield Done
      }.getOrElse {
        log.warn("3) No canonical venue found for {}", venue.loggableId)
        Future(Done)
      }
    } yield {
      done
    }
  }

  def pruneDuplicateVenues(venueName: Option[String], matchName: Boolean = true) = {
    // import scala.concurrent.duration._
    // val count = Await.result(allVenuesCount(), 10 seconds)
    // log.info("Count of the allVenuesCount query is {}", count)

    allVenuesSource(venueName)
      .mapAsync(1)(deduplicateVenue(_, matchName))
      .runFold(0)((c, _) => {
        if (c % 10000 == 0) log.debug("pruneDuplicateVenues {}", c+1)
        c + 1
      })
      .map { f =>
        log.info("done")
        f
      }
  }


  private def deduplicateEvent(event: Event): Future[Done] = {
    // find matching
    for {
      canonicalOption <- findCanonicalEntity[StoredEvent](event, EVENTS)
      done <- canonicalOption.map { canonical =>
        val storableEvent = StorableEvent(
          canonical.externalId,
          canonical.title,
          canonical.imageUrl,
          canonical.description,
          canonical.startDateTime,
          canonical.endDateTime,
          event.timezone,
          canonical.categories,
          canonical.venue,
          canonical.artist,
          canonical.url,
          canonical.ticketPurchaseUrl,
          canonical.localStartDate
        )
        for {
          matching <- findDuplicateEvents(storableEvent)

          duplicates = matching.filter(_.id != canonical.id)
          duplicateIds = duplicates.map(_.id)

          // mark duplicates for deletion
          duplicatesQuery = Json.obj("_id" -> Json.obj("$in" -> duplicateIds))
          deletedAt = DateTime.now
          duplicatesUpdate = Json.obj("$set" -> Json.obj("markedForDeletion" -> deletedAt))

          eventsCollection <- collection(EVENTS)
          _ <- eventsCollection.update(false).one(duplicatesQuery, duplicatesUpdate, upsert = false, multi = true)
        } yield Done
      }.getOrElse {
        log.warn("no canonical event found for {}", event.loggableId)
        Future(Done)
      }
    } yield {
      done
    }
  }

  def allEventsSource(eventName: Option[String]) = {
    val selector = eventName match {
      case Some(eventName) => Json.obj(
        "markedForDeletion" -> JsNull,
        "title" -> fromRegex(BSONRegex(eventName, "i"))
      )
      case None => Json.obj(
        "markedForDeletion" -> JsNull,
      )
    }

    val futureSource = for {
      c <- collection(EVENTS)
    } yield {
      val selector = Json.obj("markedForDeletion" -> JsNull)
      //      val selector = Json.obj("$text" -> Json.obj("$search" -> "wildcraft"))
      c.find[JsObject, JsObject](selector, None)
        .cursor[Event](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson(event).toString, e)
        }))
    }
    Source.fromFutureSource(futureSource)
  }

  def pruneDuplicateEvents(eventName: Option[String]) = {
    // import scala.concurrent.duration._
    // val count = Await.result(allEventsCount(eventName), 10 seconds)
    // log.info("Count of the allEventsCount query is {}", count)

    allEventsSource(eventName)
      .mapAsync(1)(deduplicateEvent)
      .runFold(0)((c, _) => {
        if (c % 10000 == 0) log.debug("pruneDuplicateEvents {}", c+1)
        c + 1
      })
      .map { f =>
        log.info("done")
        f
      }
  }



  private def deduplicateArtist(artist: Artist): Future[Done] = {
    // find matching
    for {
      canonicalOption <- findCanonicalEntity[StoredArtist](artist, ARTISTS)
      matching <- findDuplicateArtists(artist)
      done <- canonicalOption.map { canonical =>
        val duplicates = matching.filter(_.id != canonical.id)
        val duplicateIds = duplicates.map(_.id)

        // update corresponding events to point at canonical artist
        val eventsQuery = Json.obj("artist._id" -> Json.obj("$in" -> duplicateIds))
        val eventsUpdate = Json.obj("$set" -> Json.obj("artist" -> canonical))

        // mark duplicates for deletion
        val duplicatesQuery = Json.obj("_id" -> Json.obj("$in" -> duplicateIds))
        val deletedAt = DateTime.now
        val duplicatesUpdate = Json.obj("$set" -> Json.obj("markedForDeletion" -> deletedAt))

        for {
          eventsCollection <- collection(EVENTS)
          _ <- eventsCollection.update(false).one(eventsQuery, eventsUpdate, upsert = false, multi = true)
          artistsCollection <- collection(ARTISTS)
          _ <- artistsCollection.update(false).one(duplicatesQuery, duplicatesUpdate, upsert = false, multi = true)
        } yield Done
      }.getOrElse {
        log.warn("no canonical artist found for {}", artist.loggableId)
        Future(Done)
      }
    } yield {
      done
    }
  }

  def pruneDuplicateArtists() = {
    musicArtistsSource()
      .mapAsync(1)(deduplicateArtist)
      .runFold(0)((c, _) => {
        if (c % 10000 == 0) log.debug("pruneDuplicateArtists {}", c+1)
        c + 1
      })
      .map { f =>
        log.info("done")
        f
      }
  }

  def findByVenueCount(venue: Venue): Future[Long] = {
    val venueNameClause: (String, JsValueWrapper) = "venue.name" -> venue.name
    val EARTH_RADIUS_KILOMETERS: Double = 6371.0
    val DUPLICATE_RADIUS_KILOMETERS: Double = 10
    val venueLocationClause: (String, JsValueWrapper) = "venue.location" -> Json.obj(
      "$geoWithin" -> Json.obj(
        "$centerSphere" -> Json
          .arr(
            Json.arr(venue.location.longitude, venue.location.latitude),
            DUPLICATE_RADIUS_KILOMETERS / EARTH_RADIUS_KILOMETERS)
      )
    )
    val notDeletedClause: (String, JsValueWrapper) = "markedForDeletion" -> JsNull

    val eventsQuery = Json.obj(venueNameClause, venueLocationClause, notDeletedClause)

    log.debug(s"[pruneVenuesWithNoEvents] query ${eventsQuery.toString}")

    collection(EVENTS).flatMap(collection => {
      //collection.findOne[JsObject, StorableEvent](Some(eventsQuery))
      collection.countS(eventsQuery)
    })
  }
}

// { "_id" : null, "names" : [ "Tialauna", ... ] }
private case class NamesAggregationResult(names: Set[String])
private object NamesAggregationResult {
  implicit val format: OFormat[NamesAggregationResult] = Json.format[NamesAggregationResult]
}

private case class ByExternalIdSet(externalIdSet: Set[SourceIdentifier])
private object ByExternalIdSet {
  implicit val writes: OWrites[ByExternalIdSet] = (o: ByExternalIdSet) => {
    Json.obj(
      "externalIdSet" -> Json.obj(
        "$elemMatch" -> Json
          .obj("$in" -> o.externalIdSet)),
      "markedForDeletion" -> JsNull
    )
  }
}
