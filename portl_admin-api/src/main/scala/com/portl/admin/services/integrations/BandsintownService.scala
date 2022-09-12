package com.portl.admin.services.integrations
import akka.stream.Materializer
import akka.stream.scaladsl.Source
import com.github.tototoshi.csv.CSVReader
import com.portl.admin.models.bandsintown.{Artist, ArtistDescription, Event}
import com.portl.admin.models.internal
import com.portl.admin.models.portlAdmin.bulk.{ImportException, ImportResults}
import com.portl.admin.services.TimezoneResolver
import com.portl.commons.models.EventSource
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.Files.TemporaryFile
import play.api.libs.json._
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import reactivemongo.akkastream.{State, cursorProducer}
import reactivemongo.api.{Cursor, ReadPreference}
import reactivemongo.api.commands.{MultiBulkWriteResult, UpdateWriteResult}
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

class BandsintownService @Inject()(
    @NamedDatabase("bandsintown") val reactiveMongoApi: ReactiveMongoApi,
    implicit val timezoneResolver: TimezoneResolver,
    implicit val executionContext: ExecutionContext,
    implicit val materializer: Materializer,
) extends MappableEventStorageService[internal.Event] {

  val ARTISTS = "artists"
  val EVENTS = "events"
  val ARTIST_DESCRIPTIONS = "artistDescriptions"

  override val collectionName: String = EVENTS
  override implicit val format: OFormat[internal.Event] = internal.Event.eventFormat
  override def eventSource: EventSource = EventSource.Bandsintown
  override def eventsSinceSelector(since: DateTime): JsObject =
    // 2018-12-07T21:00:00
    Json.obj("datetime" -> Json.obj("$gte" -> since.toString("yyyy-MM-dd")))

  def upsertArtist(artist: JsObject): Future[UpdateWriteResult] = {
    val IMPOSSIBLE_ID = "NO SUCH ID"
    val id = (artist \ "id").validate[String] match {
      case JsSuccess(value, _) => value
      case _ =>
        log.debug(s"upsertArtist with no id: $artist")
        IMPOSSIBLE_ID
    }

    val selector = Json.obj("id" -> id)

    for {
      c <- collection(ARTISTS)
      r <- c.update(ordered = false).one(selector, artist, upsert = true)
    } yield r
  }

  def bulkUpsert(entries: Seq[JsObject],
                 idKey: String = "id",
                 collectionName: String = EVENTS): Future[MultiBulkWriteResult] = {
    val IMPOSSIBLE_ID = -1
    val (withId, noId) = entries.partition(e => (e \ idKey).validate[String].isSuccess)
    log.debug(s"bulkUpsert $collectionName {withId:${withId.length}, noId:${noId.length}}")

    if (noId.nonEmpty) {
      log.debug(s"Found objects without ids: $noId")
    }

    collection(collectionName).flatMap { collection =>
      val updateBuilder = collection.update(true)
      val updates = Future.sequence(withId.map { e =>
        updateBuilder.element(
          q = Json.obj(idKey -> (e \ idKey).get),
          u = e,
          upsert = true
        )
      } ++ noId.map { e =>
        updateBuilder.element(
          q = Json.obj(idKey -> IMPOSSIBLE_ID),
          u = e,
          upsert = true
        )
      })

      val result = updates.flatMap(ops => updateBuilder.many(ops))
      result.map{ r =>
        log.debug(s"$r")
        r
      }
    }
  }

  private def eventsSource(selector: JsObject): Future[Source[Event, Future[State]]] = {
    for {
      c <- collection
    } yield {
      c.find(selector, Some(projection))
        .cursor[JsObject](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson(event).toString, e)
        }))
        .map[JsResult[Event]](_.validate[Event])
        .filter({
          case JsSuccess(_, _) => true
          case JsError(errors) =>
            log.debug(errors.mkString(" "))
            false
        })
        .collect { case JsSuccess(e, _) => e }
    }
  }

  private def transform(bandsintownEvent: Event): Future[Option[internal.Event]] = {
    for {
      c <- collection(ARTISTS)
      artistOption <- c.find[ArtistById, JsObject](ArtistById(bandsintownEvent.artist_id), None).one[Artist]
      d <- collection(ARTIST_DESCRIPTIONS)
      descOption <- d
        .find[DescriptionByArtistId, JsObject](DescriptionByArtistId(bandsintownEvent.artist_id), None)
        .one[ArtistDescription]
    } yield {
      artistOption.map { artist =>
        bandsintownEvent.toPortl(artist, descOption)
      }
    }
  }

  override def allEventsSource: Future[Source[internal.Event, Future[State]]] = {
    for {
      s <- eventsSource(JsObject.empty)
    } yield
      s.mapAsync(1)(transform).collect {
        case Some(e) => e
      }
  }

  override def upcomingEventsSource: Future[Source[internal.Event, Future[State]]] = {
    for {
      s <- eventsSource(eventsSinceSelector(upcomingEventsStartDate))
    } yield
      s.mapAsync(1)(transform).collect {
        case Some(e) => e
      }
  }

  def bulkAddDescriptions(descriptions: Seq[ArtistDescription]): Future[MultiBulkWriteResult] = {
    bulkUpsert(descriptions.map(Json.toJsObject(_)), "artistId", ARTIST_DESCRIPTIONS)
  }

  def importDescriptions(csvFile: TemporaryFile): Future[ImportResults] = {
    val ARTIST_ID_HEADER = "artistId"
    val DESCRIPTION_HEADER = "description"

    val reader = CSVReader.open(csvFile)
    reader
      .readNext()
      .collect {
        case headers if headers.contains(ARTIST_ID_HEADER) && headers.contains(DESCRIPTION_HEADER) =>
          val idIndex = headers.indexOf(ARTIST_ID_HEADER)
          val descIndex = headers.indexOf(DESCRIPTION_HEADER)
          Source(reader.toStream)
            .map { row =>
              val id = row.lift(idIndex).getOrElse("")
              val desc = row.lift(descIndex).getOrElse("")
              if (id.nonEmpty && desc.nonEmpty) Some(ArtistDescription(id, desc)) else None
            }
            .collect { case Some(d) => d }
            .batch(1000, Seq(_))(_ :+ _)
            .mapAsync(1)(bulkAddDescriptions)
            .runFold(ImportResults.empty)(_ merge _)
        case _ => Future.failed(ImportException(s"""Missing headers "$ARTIST_ID_HEADER", "$DESCRIPTION_HEADER""""))
      }
      .getOrElse {
        Future.failed(ImportException("Empty file"))
      }
  }
}

case class ArtistById(id: String)
object ArtistById {
  implicit val format: OFormat[ArtistById] = Json.format[ArtistById]
}

case class DescriptionByArtistId(artistId: String)
object DescriptionByArtistId {
  implicit val format: OFormat[DescriptionByArtistId] = Json.format[DescriptionByArtistId]
}
