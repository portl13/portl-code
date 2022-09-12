package com.portl.api.services

import com.portl.api.models.internal.IdAggregationResult
import com.portl.api.services.queries.EventQueries._
import com.portl.api.services.queries.Queries
import javax.inject.Inject

import scala.concurrent.{ExecutionContext, Future}
import com.portl.commons.models._
import com.portl.commons.models.base.MongoObjectId
import com.portl.commons.serializers.Mongo._
import com.portl.commons.services.{PaginationParams, SingleCollectionService}
import org.joda.time.DateTime
import play.api.libs.json._
import play.modules.reactivemongo._
import reactivemongo.api.{CursorOptions, ReadConcern, ReadPreference}
import reactivemongo.play.json.compat._
import squants.space.Length
import squants.space.LengthConversions._

class EventService @Inject()(val reactiveMongoApi: ReactiveMongoApi,
                             implicit val executionContext: ExecutionContext,
                             configuration: play.api.Configuration)
    extends SingleCollectionService[StoredEvent] {

  val EVENTS = "events"
  val HISTORICAL_EVENTS = "historicalEvents"

  val collectionName = EVENTS
  private val defaultSearchRadius = configuration.underlying.getInt("com.portl.api.defaultSearchRadiusMiles").miles
  private val defaultStartTimeWindowDays = configuration.underlying.getInt("com.portl.api.defaultStartTimeWindowDays")

  def sortByLocalStartDate: JsObject = Json.obj("localStartDate" -> 1)

  def findPaginatedIdsNear(location: Location,
                           paginationParams: PaginationParams,
                           maxDistance: Option[Length] = None,
                           startingAfter: Option[DateTime] = None,
                           startingWithinDays: Option[Int] = None,
                           categories: Option[List[String]] = None): Future[IdAggregationResult] = {
    val dist = maxDistance.getOrElse(defaultSearchRadius)
    val offset = paginationParams.page * paginationParams.pageSize
    val limit = paginationParams.pageSize

    val startingQuery = startingAfter.map { startDate =>
      var q = Json.obj(
        "$gt" -> Json.toJson(startDate)
      )
      startingWithinDays.foreach(days => q ++= Json.obj("$lt" -> Json.toJson(startDate.plusDays(days))))
      Json.obj(
        "startDateTime" -> q
      )
    }

    val categoryQuery = categories map { categories =>
      Json.obj(
        "categories" -> Json.obj("$in" -> categories)
      )
    }

    val query = Seq(startingQuery, categoryQuery).flatten.foldLeft(Json.obj())(_ ++ _) ++ Queries.notMarkedForDeletion

    withCollection { c =>
      import c.BatchCommands.AggregationFramework._

      val pipe = List(
        Sort(Ascending("startDateTime")),
        // Create one group with an overall count and list of all result ids.
        Group(JsNull)("count" -> SumAll, "ids" -> PushField("_id")),
        // Slice the result ids based on the provided pagination.
        Project(Json.obj("count" -> 1, "ids" -> Json.obj("$slice" -> Json.arr("$ids", offset, limit))))
      )

      c.withReadPreference(ReadPreference.secondaryPreferred)
        .aggregatorContext[IdAggregationResult](
          c.geoNear(location, Some(dist), Some("computedDistance"), Some(query)),
          pipe,explain = false,
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
        .headOption
        // The group stage does not yield a document if there are no matching events. Handle that case here.
        .map(_.getOrElse(IdAggregationResult(Seq.empty, 0)))
    }
  }

  def findAllCategories: Future[Seq[EventCategory]] = {
    Future(EventCategory.values)
  }

  def findByArtist(artist: StoredArtist,
                   pagination: Option[PaginationParams] = None,
                   startingAfter: Option[DateTime] = None,
                   startingWithinDays: Option[Int] = None): Future[List[StoredEvent]] = {

    val query = EventsByArtist(
      artist,
      startingAfter.map(a => EventsByStartTime(a, a.plusDays(startingWithinDays.getOrElse(defaultStartTimeWindowDays))))
    )

    val sort = Json.obj("startDateTime" -> 1)

    withCollection { c =>
      pagination match {
        case Some(p) =>
          c.findListSortedPaginated[EventsByArtist, StoredEvent](
            query,
            sort,
            p.page,
            p.pageSize
          )
        case _ =>
          c.findListSorted[EventsByArtist, StoredEvent](
            query,
            sort
          )
      }

    }
  }

  def findByVenue(venue: StoredVenue,
                  pagination: Option[PaginationParams] = None,
                  startingAfter: Option[DateTime] = None,
                  startingWithinDays: Option[Int] = None): Future[List[StoredEvent]] = {
    val query = EventsByVenue(
      venue,
      startingAfter.map(a => EventsByStartTime(a, a.plusDays(startingWithinDays.getOrElse(defaultStartTimeWindowDays))))
    )
    val sort = Json.obj("startDateTime" -> 1)

    withCollection { c =>
      pagination match {
        case Some(p) =>
          c.findListSortedPaginated[EventsByVenue, StoredEvent](
            query,
            sort,
            p.page,
            p.pageSize
          )
        case _ =>
          c.findListSorted[EventsByVenue, StoredEvent](
            query,
            sort
          )
      }
    }
  }

  def findListSortedPaginated(selector: JsObject,
                              sortBy: JsObject = sortByObjectId,
                              page: Int,
                              itemsPerPage: Int): Future[List[StoredEvent]] = {
    withCollection { _.findListSortedPaginated[JsObject, StoredEvent](selector, sortBy, page, itemsPerPage) }
  }

  def findListSorted(selector: JsObject, sortBy: JsObject = sortByObjectId): Future[List[StoredEvent]] = {
    withCollection { _.findListSorted[JsObject, StoredEvent](selector, sortBy) }
  }

  def count(selector: JsObject): Future[Long] = {
    withCollection { _.countS(selector) }
  }

  // Support for historical events
  override def findById(id: MongoObjectId)(implicit reads: Reads[StoredEvent]): Future[Option[StoredEvent]] = {
    // try to find in history, fall back to finding in the future
    for {
      historicalEventOption <- byObjectId[StoredEvent](collection(HISTORICAL_EVENTS), id)
      eventOption <- if (historicalEventOption.isDefined) Future(historicalEventOption)
      else byObjectId[StoredEvent](collection(EVENTS), id)
    } yield eventOption
  }

  def findByIds(ids: Iterable[MongoObjectId]): Future[List[StoredEvent]] = {
    for {
      historicalCollection <- collection(HISTORICAL_EVENTS)
      historicalEvents <- historicalCollection
        .findListSorted[JsObject, StoredEvent](queryByObjectIds(ids), sortByLocalStartDate)
      upcomingEvents <- findListSorted(queryByObjectIds(ids), sortByLocalStartDate)
    } yield historicalEvents ++ upcomingEvents
  }
}
