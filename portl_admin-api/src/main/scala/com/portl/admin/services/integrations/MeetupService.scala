package com.portl.admin.services.integrations

import akka.NotUsed
import akka.actor.{Actor, ActorRef, ActorSystem, PoisonPill, Props}
import akka.pattern.ask
import akka.stream._
import akka.stream.scaladsl.{Sink, Source}
import com.portl.admin.models.backgroundTask.{Task, TaskStatus}
import com.portl.admin.models.meetup.remote.{SearchParams, SearchResult}
import com.portl.admin.models.meetup.{Event, LatestMTime}
import com.portl.admin.services.LocalDataService
import com.portl.admin.services.background.BackgroundTaskService
import com.portl.commons.futures.FutureHelpers
import com.portl.commons.models.base.MongoObjectId
import com.portl.commons.models.{EventSource, Location}
import javax.inject.{Inject, Singleton}
import org.joda.time.DateTime
import play.api.libs.json._
import play.api.libs.ws.{WSClient, WSRequest}
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import reactivemongo.api.commands.{MultiBulkWriteResult, UpdateWriteResult}
import reactivemongo.play.json.compat._

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future, Promise}

case class SearchRequest(replyTo: ActorRef, params: SearchParams)
class MeetupEventCollector(muService: MeetupService) extends Actor {
  import context.dispatcher

  override def receive: Receive = {
    case SearchRequest(replyTo, params) =>
      muService.getRawData(params).map(replyTo ! _)
  }
}

class MeetupEventDispatcher(throttler: ActorRef) extends Actor {

  var replyTo: Option[ActorRef] = None

  override def receive: Receive = {
    case s: SearchParams =>
      replyTo = Some(sender)
      throttler ! SearchRequest(self, s)
    case json: JsValue =>
      replyTo foreach (_ ! json)
      self ! PoisonPill
  }
}

@Singleton
class MeetupService @Inject()(configuration: play.api.Configuration,
                              system: ActorSystem,
                              implicit val executionContext: ExecutionContext,
                              implicit val materializer: Materializer,
                              ws: WSClient,
                              @NamedDatabase("meetup") val reactiveMongoApi: ReactiveMongoApi,
                              localDataService: LocalDataService,
                              backgroundTaskService: BackgroundTaskService)
    extends MappableEventStorageService[Event] {

  private val throttleRequestsPer = 2
  private val throttleRequestsDuration = 1.second

  private val apiToken = configuration.underlying.getString("com.portl.integrations.meetup.token")

  override val eventSource: EventSource = EventSource.Meetup
  val collectionName = "events"
  override implicit val format: OFormat[Event] = Event.eventFormat

  override def eventsSinceSelector(since: DateTime): JsObject =
    // "time" : NumberLong("1543086000000"), (millis)
    Json.obj("time" -> Json.obj("$gte" -> since.getMillis))

  val meetupEventCollector = system.actorOf(Props(classOf[MeetupEventCollector], this))
  val throttledEventCollector: ActorRef =
    Source
      .actorRef(bufferSize = 100000, OverflowStrategy.fail)
      .throttle(throttleRequestsPer, throttleRequestsDuration, throttleRequestsPer, ThrottleMode.shaping)
      .to(Sink.actorRef(meetupEventCollector, NotUsed))
      .run()

  def getRawData(params: SearchParams): Future[JsValue] = {
    // NOTE: rate limit looks like ~30 per 10s
    // X-RateLimit-Remaining -> Buffer(29)
    val request: WSRequest = ws
      .url("https://api.meetup.com/2/open_events")
      .addHttpHeaders("Accept" -> "*/*")
      .addQueryStringParameters("lon" -> params.location.longitude.toString)
      .addQueryStringParameters("lat" -> params.location.latitude.toString)
      .addQueryStringParameters("radius" -> "smart")
      .addQueryStringParameters("page" -> "300")
      .addQueryStringParameters("offset" -> params.offset.toString)
      .addQueryStringParameters("key" -> apiToken)
    log.debug(request.toString)
    request.get().map { r =>
      log.debug(s"${r.status} ${r.statusText} ${r.headers}")
      r.json
    }
  }

  def getData(params: SearchParams): Future[SearchResult] = {
    this.getRawData(params).flatMap { js =>
      val result = js.as[SearchResult]
      result.results match {
        case results: List[JsObject] if results.nonEmpty => bulkUpsert(result.results).map(_ => result)
        case _ => {
          log.warn(s"Got back empty results $js")
          Future(result)
        }
      }
    }
  }

  def getThrottledData(params: SearchParams): Future[SearchResult] = {
    this.makeThrottledRequest(params).flatMap { js =>
      val result = js.as[SearchResult]
      result.results match {
        case results: List[JsObject] if results.nonEmpty => bulkUpsert(result.results).map(_ => result)
        case _ => {
          log.warn(s"Got back empty results $js")
          Future(result)
        }
      }
    }
  }

  def makeThrottledRequest(params: SearchParams): Future[JsValue] = {
    val meetupDispatcher = system.actorOf(Props(classOf[MeetupEventDispatcher], throttledEventCollector))
    implicit val timeout = akka.util.Timeout(60.second)
    (meetupDispatcher ? params).mapTo[JsValue]
  }

  def collectSearchResults(location: Location, maxPages: Int = 200): Future[Unit] = {
    log.info(s"Collecting meetup results for ${location.longitude},${location.latitude}")
    val promise = Promise[Unit]()

    def shouldContinue(response: SearchResult): Boolean = {
      !"".equals(response.meta.next) // Could it be so simple?
    }

    def getRemainingPages(params: SearchParams): Future[Unit] = {
      log.debug(s"getRemainingPages params: $params")
      for {
        searchResult <- getThrottledData(params)
      } yield {
        log.debug(s"searchResult count: ${searchResult.results.length}, meta: ${Json.toJson(searchResult.meta)}")
        if (shouldContinue(searchResult))
          getRemainingPages(params.copy(offset = params.offset + 1))
        else
          promise.success(())
      }
    }

    getRemainingPages(SearchParams(location))
    promise.future
  }

  def collectEventsForUSCities(): Future[Unit] = {
    val task = Task(
      MongoObjectId.generate,
      TaskStatus.InProgress,
      "Collect Meetup events",
      JsObject.empty,
      DateTime.now,
      JsObject.empty)
    for {
      _ <- backgroundTaskService.insert(task)
      locations <- localDataService.usCityLocations()
      indexedLocations = locations zip (1 to locations.length)
      _ <- FutureHelpers.executeSequentially(indexedLocations) {
        case (location, index) =>
          backgroundTaskService
            .update(task.copy(extra = Json.obj("current" -> s"$index of ${locations.length}")))
            .flatMap(_ => collectSearchResults(location))
      }
      _ <- backgroundTaskService.update(task.copy(status = TaskStatus.Completed, extra = JsObject.empty))
    } yield ()
  }

  def bulkUpsert(events: Seq[JsObject]): Future[MultiBulkWriteResult] = {
    val IMPOSSIBLE_ID = -1
    val (withId, noId) = events.partition(e => (e \ "id").validate[String].isSuccess)
    log.debug(s"bulkUpsert {withId:${withId.length}, noId:${noId.length}}")

    if (noId.nonEmpty) {
      log.debug(s"Found objects without ids: $noId")
    }

    withCollection { collection =>
      val updateBuilder = collection.update(true)
      val updates = Future.sequence(withId.map { e =>
        updateBuilder.element(
          q = Json.obj("id" -> (e \ "id").get),
          u = e,
          upsert = true
        )
      } ++ noId.map { e =>
        updateBuilder.element(
          q = Json.obj("id" -> IMPOSSIBLE_ID),
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

  def getLatestMTime: Future[Option[Long]] = {
    for {
      c <- collection("mtime")
      doc <- c.findOne[JsObject, LatestMTime](JsObject.empty)
    } yield doc.map(_.mtime)
  }

  def setLatestMTime(mtime: Long): Future[UpdateWriteResult] = {
    collection("mtime").flatMap(_.update(true).one(JsObject.empty, LatestMTime(mtime), upsert = true))
  }
}
