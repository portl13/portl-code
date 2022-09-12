package com.portl.admin.services.integrations

import akka.stream.Materializer
import com.javadocmd.simplelatlng.util.LengthUnit
import com.javadocmd.simplelatlng.{Geohasher, LatLng}
import com.portl.admin.models.ticketmaster.remote.SearchResult
import com.portl.admin.models.ticketmaster.v1
import com.portl.admin.services.background.BackgroundTaskService
import com.portl.commons.futures.FutureHelpers
import com.portl.commons.models.EventSource
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.json._
import play.api.libs.ws.{WSClient, WSRequest}
import play.modules.reactivemongo._
import reactivemongo.api.commands.MultiBulkWriteResult
import reactivemongo.api.Cursor
import reactivemongo.play.json.compat._

import scala.collection.mutable
import scala.concurrent.{ExecutionContext, Future}

class TicketmasterService @Inject()(configuration: play.api.Configuration,
                                    implicit val executionContext: ExecutionContext,
                                    implicit val materializer: Materializer,
                                    implicit val backgroundTaskService: BackgroundTaskService,
                                    ws: WSClient,
                                    @NamedDatabase("ticketmaster") val reactiveMongoApi: ReactiveMongoApi)
    extends MappableEventStorageService[v1.Event] {

  private val apiToken = configuration.underlying.getString("com.portl.integrations.ticketmaster.token")
  private val dateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

  override val eventSource: EventSource = EventSource.Ticketmaster
  override val collectionName: String = "events"
  override implicit val format: OFormat[v1.Event] = v1.Event.eventFormat

  override def eventsSinceSelector(since: DateTime): JsObject =
    Json.obj("eventStartLocalDate" -> Json.obj("$gte" -> since.toString("yyyy-MM-dd")))

  def maxPages: Int = 5

  def getPageCount(params: Map[String, String]): Future[Int] = {
    this.getRawData(params, 1).map { js =>
      println("Got raw data")
      println(js.toString())
      val results = js.as[SearchResult]
      val total = results.page.totalPages
      println(s"$total")
      this.processRawData(results)

      total
    }
  }

  def getResultSetSize(params: Map[String, String]): Future[Int] = {
    this.getRawData(params, 1).map { js =>
      val results = js.as[SearchResult]
      val total = results.page.totalElements
      total
    }
  }

  def shouldRefineSearch(searchResult: SearchResult): Boolean = {
    searchResult.page.totalElements > 1000
  }

  def getSearchParams(latLng: LatLng,
                      radius: Double,
                      after: Option[DateTime],
                      before: Option[DateTime]): Map[String, String] = {
    val geoPoint = Geohasher.hash(latLng)
    val a: Option[String] = after.map(_.toString(dateTimeFormat))
    val b: Option[String] = before.map(_.toString(dateTimeFormat))
    val result = mutable.Map(
      "geoPoint" -> geoPoint.substring(0, Math.min(geoPoint.length, 9)), // Must be under 10 characters.
      "radius" -> Math.ceil(radius).toInt.toString, // Default unit is miles. Must be an Int.
      "countryCode" -> "US", // Setting this here until we care about other countries
      "units" -> "km" // Use kilometers
    )
    a.foreach(result += "startDateTime" -> _)
    b.foreach(result += "endDateTime" -> _)
    result.toMap
  }

  def getRawData(params: Map[String, String], page: Int): Future[JsValue] = {
    var request: WSRequest = ws
      .url("https://app.ticketmaster.com/discovery/v2/events.json")
      .addHttpHeaders("Accept" -> "application/json")
      .addQueryStringParameters("size" -> "200")
      .addQueryStringParameters("page" -> page.toString)
      .addQueryStringParameters("apikey" -> apiToken)
    for ((k, v) <- params) request = request.addQueryStringParameters(k -> v)
    log.debug(request.uri.toString)
    request.get().map(_.json)
  }

  def bulkUpsert(events: Seq[JsObject]): Future[MultiBulkWriteResult] = {
    val IMPOSSIBLE_ID = -1
    val (withId, noId) = events.partition(e => (e \ "eventId").validate[String].isSuccess)
    log.debug(s"bulkUpsert {withId:${withId.length}, noId:${noId.length}}")

    if (noId.nonEmpty) {
      log.debug(s"Found objects without eventIds: $noId")
    }

    withCollection { collection =>
      val updateBuilder = collection.update(true)
      val updates = Future.sequence(withId.map { e =>
        updateBuilder.element(
          q = Json.obj("eventId" -> (e \ "eventId").get),
          u = e,
          upsert = true
        )
      } ++ noId.map { e =>
        updateBuilder.element(
          q = Json.obj("eventId" -> IMPOSSIBLE_ID),
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

  def processRawData(results: SearchResult): Future[Unit] = {
    val maybeEvents: Option[List[JsObject]] = results._embedded.map(_.events)
    val thing: Option[Future[Boolean]] = maybeEvents.map { events =>
      log.debug(s"Processing ${events.length} events")
      insertManyEvents(events)
    }
    thing.getOrElse(Future.successful(Unit)).map(_ => Unit)
  }

  def getData(params: Map[String, String], page: Int): Future[SearchResult] = {
    println(s"Getting data for page $page")
    for {
      js <- getRawData(params, page)
      result = js.as[SearchResult]
      _ <- processRawData(result)
    } yield result
  }

  def processData(params: Map[String, String], page: Int) = {
    for {
      js <- getRawData(params, page)
      result = js.as[SearchResult]
      _ <- processRawData(result)
    } yield Unit
  }

  def getDistanceUnit(): LengthUnit = {
    LengthUnit.KILOMETER
  }

  def getClassifications(): Future[JsValue] = {
    val request: WSRequest = ws
      .url("https://app.ticketmaster.com/discovery/v2/classifications")
      .addHttpHeaders("Accept" -> "application/json")
      .addQueryStringParameters("apikey" -> apiToken)

    request.get().map { response =>
      response.json
    }
  }

  private def insertEvent(event: JsObject): Future[Boolean] = {
    collection.flatMap { c =>
      (event \ "eventId").validate[String] match {
        case JsSuccess(id, _) =>
          c.update(true).one(
              Json.obj("eventId" -> id),
              event,
              upsert = true
            )
            .map(_.ok)
        case _ =>
          log.warn(s"Found event without eventId: $event")
          collection
            .flatMap(_.insert(false).one(event))
            .map(_.ok)
      }
    }
  }

  private def insertManyEvents(events: List[JsObject]): Future[Boolean] = {
    insertManyRecords(events)(insertEvent)
  }

  private def insertManyRecords[T](records: Iterable[T])(insertFn: T => Future[Boolean]): Future[Boolean] = {
    FutureHelpers.executeSequentially(records)(insertFn) map {
      case Nil      => true
      case statuses => statuses reduce { _ && _ }
    }
  }

  def fetchAllEvents: Future[List[v1.Event]] = {
    collection
      .map {
        _.find[JsObject, JsObject](JsObject.empty, None).cursor[v1.Event]()
      }
      .flatMap(_.collect[List](-1, Cursor.ContOnError[List[v1.Event]]()))
  }
}
