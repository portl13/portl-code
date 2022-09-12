package com.portl.admin.actors.collection
import java.util.concurrent.atomic.AtomicLong

import akka.Done
import akka.actor.{Actor, FSM}
import akka.stream.{KillSwitch, KillSwitches, Materializer}
import akka.stream.scaladsl.{Keep, Sink, Source}
import akka.util.ByteString
import com.portl.admin.services.integrations.{RequestFailedException, SongkickService}
import com.portl.admin.streams.JSONFeed
import javax.inject.Inject
import play.api.Configuration
import play.api.libs.json.{JsObject, Json}
import play.api.libs.ws.{WSClient, WSRequest}

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

object SongkickCollector {
  // internal messages
  private case class GotFeed(feed: Source[ByteString, _])
  private case object FinishedFeed
  private case object Failed

  trait Data
  case object EmptyData extends Data
  case class ProcessingFeedData(killSwitch: KillSwitch, count: AtomicLong) extends Data

  sealed trait State
  case object Stopped extends State
  case object FetchingFeed extends State
  case object ProcessingFeed extends State
}

class SongkickCollector @Inject()(service: SongkickService,
                                  wsClient: WSClient,
                                  configuration: Configuration,
                                  implicit val executionContext: ExecutionContext,
                                  implicit val materializer: Materializer)
    extends Actor
    with FSM[SongkickCollector.State, SongkickCollector.Data] {
  import SongkickCollector._
  import com.portl.admin.actors.SharedMessages._

  private val apiToken = configuration.get[String]("com.portl.integrations.songkick.token")

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      getFeedData().onComplete {
        case Success(feed) =>
          log.debug("{} received feed response", service.eventSource.toString)
          self ! GotFeed(feed)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! Failed
      }
      goto(FetchingFeed)
  }

  when(FetchingFeed) {
    case Event(GotFeed(feed), _) =>
      val (ks, count, done) = processFeedData(feed)
      done.onComplete {
        case Success(_) =>
          log.debug("{} finished processing feed", service.eventSource.toString)
          self ! FinishedFeed
        case Failure(IntentionallyStoppedException) =>
          log.info("{} collection intentionally stopped", service.eventSource.toString)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! Failed
      }
      goto(ProcessingFeed) using ProcessingFeedData(ks, count)
  }

  when(ProcessingFeed) {
    case Event(FinishedFeed, _) =>
      goto(Stopped)
  }

  whenUnhandled {
    case Event(Stop, ProcessingFeedData(killSwitch, _)) =>
      killSwitch.abort(IntentionallyStoppedException)
      goto(Stopped)
    case Event(Stop, _) =>
      goto(Stopped)
    case Event(QueryStatus, _) =>
      stay replying currentStatus
  }

  onTransition {
    case (Stopped, x) if x != Stopped =>
      service.countAllEvents.map(c =>
        log.info("{} collection started with {} existing events", service.eventSource.toString, c))
    case (x, Stopped) if x != Stopped =>
      service.countAllEvents.map(c =>
        log.info("{} collection stopped with {} existing events", service.eventSource.toString, c))
  }

  initialize()

  def currentStatus: JsObject = {
    // Note: IntelliJ highlights the `->` red, but it compiles fine. IDE must be confused about the FSM.`->` extractor.
    val serializedData: JsObject = stateData match {
      case EmptyData => JsObject.empty
      case ProcessingFeedData(_, count) =>
        Json.obj("count" -> count.get)
    }
    Json.obj(
      "state" -> stateName.toString,
      "data" -> serializedData
    )
  }

  private def processFeedData(source: Source[ByteString, _],
                              batchSize: Int = 100,
                              parallelism: Int = 1): (KillSwitch, AtomicLong, Future[Done]) = {
    val count = new AtomicLong(0)
    val unzippedContent = JSONFeed(source, "event")
    // discard
    log.debug(s"valuesBeforeStreamField: ${unzippedContent.valuesBeforeStreamField()}")
    val (ks, done) = unzippedContent
      .streamFieldContents()
      .collectType[JsObject]
      .alsoTo(Sink.foreach(_ => count.incrementAndGet))
      .viaMat(KillSwitches.single)(Keep.right)
      .grouped(batchSize)
      .mapAsyncUnordered(parallelism)(service.bulkUpsert(_))
      .toMat(Sink.ignore)(Keep.both)
      .run()
    (ks, count, done)
  }

  private def getFeedData(full: Boolean = false): Future[Source[ByteString, _]] = {
    // TODO : retry on failure
    // TODO : support calling with full: true on demand
    val url =
      if (full) "https://api.songkick.com/api/3.0/events/upcoming.gz"
      else "https://api.songkick.com/api/3.0/events/recent_upcoming.gz"
    val request: WSRequest = wsClient
      .url(url)
      .withMethod("GET")
      .addQueryStringParameters("apikey" -> apiToken)
    log.debug(request.uri.toString)

    request
      .get()
      .map { r =>
        r.status match {
          case 200 =>
            log.debug(s"${r.status} ${r.statusText} ${r.headers}")
            r
          case _ =>
            log.warning(s"${r.status} ${r.statusText} ${r.headers}")
            throw RequestFailedException(s"${r.status} ${r.statusText} ${r.headers}")
        }
      }
      .map(_.bodyAsSource)
  }
}
