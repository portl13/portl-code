package com.portl.admin.services.integrations

import akka.stream.Materializer
import com.portl.admin.models.eventbrite.Event
import com.portl.admin.models.eventbrite.remote.LocationBasedSearchResult
import com.portl.admin.services.background.BackgroundTaskService
import com.portl.commons.models.EventSource
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.json._
import play.api.libs.ws._
import play.modules.reactivemongo._
import reactivemongo.api.commands.UpdateWriteResult
import reactivemongo.api.{Cursor, ReadPreference}
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

class EventbriteService @Inject()(configuration: play.api.Configuration,
                                  implicit val executionContext: ExecutionContext,
                                  implicit val materializer: Materializer,
                                  implicit val backgroundTaskService: BackgroundTaskService,
                                  ws: WSClient,
                                  @NamedDatabase("eventbrite") val reactiveMongoApi: ReactiveMongoApi)
    extends MappableEventStorageService[Event] {

  private val apiToken = configuration.underlying.getString("com.portl.integrations.eventbrite.token")

  override val eventSource: EventSource = EventSource.Eventbrite
  override val collectionName: String = "events"
  override implicit val format: OFormat[Event] = Event.eventFormat

  override def eventsSinceSelector(since: DateTime): JsObject =
    Json.obj("start.local" -> Json.obj("$gte" -> since.toString("yyyy-MM-dd")))

  def getRawData(lat: String, lng: String, radius: String): Future[JsValue] = {
    val request: WSRequest = ws
      .url("https://www.eventbriteapi.com/v3/events/search/")
      .addHttpHeaders("Accept" -> "*/*")
      .addQueryStringParameters("location.latitude" -> lat)
      .addQueryStringParameters("location.longitude" -> lng)
      .addQueryStringParameters("location.within" -> radius)
      .addQueryStringParameters("expand" -> "venue,category")
      .addQueryStringParameters("token" -> apiToken)
    request.get().map(_.json)
  }

  def getData(lat: String, lng: String, radius: String): Future[LocationBasedSearchResult] = {
    this.getRawData(lat, lng, radius).flatMap { js =>
      val results = js.as[LocationBasedSearchResult]
      insertManyEvents(results.events).map(_ => results)
    }
  }

  def bulkUpsert(events: List[JsObject]): Future[UpdateWriteResult] = {
    // "id": "45555854788"
    val IMPOSSIBLE_ID = "no way"
    val (withId, noId) = events.partition(e => (e \ "id").validate[String].isSuccess)
    log.debug(s"bulkUpsert {withId:${withId.length}, noId:${noId.length}}")

    if (noId.nonEmpty) {
      log.debug(s"Found objects without ids: $noId")
    }

    withCollection { collection =>
      import collection.BatchCommands._
      import UpdateCommand._
      val updates = withId.map { e =>
        UpdateElement(
          q = Json.obj("id" -> (e \ "id").get),
          u = e,
          upsert = true
        )
      } ++ noId.map { e =>
        UpdateElement(
          q = Json.obj("id" -> IMPOSSIBLE_ID),
          u = e,
          upsert = true
        )
      }
      val update = Update(updates.head, updates.tail: _*)
      collection.runCommand(update, ReadPreference.primary).map { r =>
        log.debug(s"$r")
        r
      }
    }
  }

  private def insertEvent(event: JsObject): Future[Boolean] = {
    collection.flatMap { c =>
      (event \ "id").validate[String] match {
        case id: JsSuccess[String] =>
          c.update(ordered = false).one(
              Json.obj("id" -> id.get),
              event,
              upsert = true
            )
            .map(_.ok)
        case _ =>
          log.warn(s"Found event without id: $event")
          collection
            .flatMap(_.insert(ordered = false).one(event))
            .map(_.ok)
      }
    }
  }

  private def insertManyEvents(events: List[JsObject]): Future[Boolean] = {
    if (events.nonEmpty)
      Future.reduceLeft(events.map(insertEvent)) { (ok, next) =>
        ok && next
      } else
      Future.successful(true)
  }

  def fetchAllEvents: Future[List[Event]] = {
    collection
      .map {
        _.find[JsObject, JsObject](JsObject.empty, None).cursor[Event]()
      }
      .flatMap(_.collect[List](-1, Cursor.ContOnError[List[Event]]()))
  }
}
