package com.portl.admin.actors.collection

import java.util.concurrent.atomic.AtomicLong

import akka.Done
import akka.actor.{Actor, FSM}
import akka.stream.scaladsl.{Keep, Sink, Source}
import akka.stream.{KillSwitch, KillSwitches, Materializer}
import akka.util.ByteString
import com.portl.admin.models.ticketmaster.remote.{CountryFeeds, FeedDescription, FeedListResponse}
import com.portl.admin.services.integrations.{PORTLService, TicketmasterService}
import com.portl.admin.streams.JSONFeed
import javax.inject.Inject
import play.api.Configuration
import play.api.libs.json._
import play.api.libs.ws.{WSClient, WSRequest}

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

object TicketmasterCollector {
  // internal messages
  private case class GotFeedList(feedDescriptions: Seq[FeedDescription])
  private case class GotFeed(feed: Source[ByteString, _])
  private case object FinishedFeed
  private case object Failed

  trait Data
  case object EmptyData extends Data
  case class FetchingFeedData(count: AtomicLong, remainingFeeds: Seq[FeedDescription], currentFeed: FeedDescription)
      extends Data
  case class ProcessingFeedData(killSwitch: KillSwitch,
                                count: AtomicLong,
                                remainingFeeds: Seq[FeedDescription],
                                currentFeed: FeedDescription)
      extends Data

  sealed trait State
  case object Stopped extends State
  case object FetchingFeedList extends State
  case object FetchingFeed extends State
  case object ProcessingFeed extends State
}

/**
  * Actor that collects data from the Ticketmaster API.
  *
  * Some potential improvements:
  *
  * Use child actors for the various tasks
  * - Fetch list of feeds
  * - Fetch a given feed
  * - Process a given feed
  *
  * Separate actions that happen on state transition from the transition definitions themselves (use onTransition).
  * This proved problematic because onTransition cannot redefine nextStateData. Specifically,
  * FetchingFeed -> ProcessingFeed kicks off a stream, and we want to hang onto the returned killSwitch. Starting that
  * stream processing in onTransition means we'd have to store the killSwitch in a var on the actor or something like
  * that. Starting the processing during the message handler means we get to put the killSwitch into the next stateData
  * object.
  */
class TicketmasterCollector @Inject()(configuration: Configuration,
                                      val portlService: PORTLService,
                                      val service: TicketmasterService,
                                      val wsClient: WSClient,
                                      implicit val executionContext: ExecutionContext,
                                      implicit val materializer: Materializer)
    extends Actor
    with FSM[TicketmasterCollector.State, TicketmasterCollector.Data] {
  import TicketmasterCollector._
  import com.portl.admin.actors.SharedMessages._

  private val apiToken = configuration.get[String]("com.portl.integrations.ticketmaster.token")

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      getAvailableFeeds.onComplete {
        case Success(feedDescriptions) =>
          log.debug("{} received available feeds ({})", service.eventSource.toString, feedDescriptions.length)
          self ! GotFeedList(feedDescriptions)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! Failed
      }
      goto(FetchingFeedList)
  }

  when(FetchingFeedList) {
    case Event(GotFeedList(feedDescriptions), _) if feedDescriptions.nonEmpty =>
      val feedDescription = feedDescriptions.head
      fetchFeedData(feedDescription.uri).onComplete {
        case Success(feed) =>
          log.debug("{} received feed response ({})", service.eventSource.toString, feedDescription.uri)
          self ! GotFeed(feed)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! Failed
      }
      goto(FetchingFeed) using FetchingFeedData(new AtomicLong(0), feedDescriptions.tail, feedDescription)
    case Event(GotFeedList(_), _) =>
      log.info("{} collection finished: {}", service.eventSource.toString, currentStatus)
      goto(Stopped)
  }

  when(FetchingFeed) {
    case Event(GotFeed(feed), FetchingFeedData(count, remainingFeeds, currentFeed)) =>
      val (killSwitch, futureDone) = processFeedData(feed, count)
      futureDone.onComplete {
        case Success(_) =>
          log.debug("{} finished processing feed {}", service.eventSource.toString, currentFeed.uri)
          self ! FinishedFeed
        case Failure(IntentionallyStoppedException) =>
          log.info("{} collection intentionally stopped", service.eventSource.toString)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! Failed
      }
      goto(ProcessingFeed) using ProcessingFeedData(killSwitch, count, remainingFeeds, currentFeed)
  }

  when(ProcessingFeed) {
    case Event(FinishedFeed, ProcessingFeedData(_, count, remainingFeeds, _)) if remainingFeeds.nonEmpty =>
      val feedDescription = remainingFeeds.head
      fetchFeedData(feedDescription.uri).onComplete {
        case Success(feed) =>
          log.debug("{} received feed response ({})", service.eventSource.toString, feedDescription.uri)
          self ! GotFeed(feed)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! Failed
      }
      goto(FetchingFeed) using FetchingFeedData(count, remainingFeeds.tail, feedDescription)
    case Event(FinishedFeed, _) =>
      log.info("{} collection finished: {}", service.eventSource.toString, currentStatus)
      goto(Stopped)
  }

  whenUnhandled {
    case Event(Stop, ProcessingFeedData(killSwitch, _, _, _)) =>
      killSwitch.abort(IntentionallyStoppedException)
      goto(Stopped)
    case Event(Stop, _) =>
      goto(Stopped)
    case Event(Failed, _) =>
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
      case FetchingFeedData(count, remainingFeeds, currentFeed) =>
        Json.obj("count" -> count.get, "remainingFeeds" -> remainingFeeds.length, "currentFeed" -> currentFeed.uri)
      case ProcessingFeedData(_, count, remainingFeeds, currentFeed) =>
        Json.obj("count" -> count.get, "remainingFeeds" -> remainingFeeds.length, "currentFeed" -> currentFeed.uri)
    }
    Json.obj(
      "state" -> stateName.toString,
      "data" -> serializedData
    )
  }

  private def getAvailableFeeds: Future[Seq[FeedDescription]] = {
    val request: WSRequest = wsClient
      .url("https://app.ticketmaster.com/discovery-feed/v2/events")
      .withMethod("GET")
      .addQueryStringParameters("apikey" -> apiToken)
    log.debug(request.uri.toString)

    request
      .get()
      .map { r =>
        log.debug(s"${r.status} ${r.statusText} ${r.headers}")
        r.json
      }
      .map(_.as[FeedListResponse])
      .map(_.countries)
      // We don't know or care what country codes will be included as keys - just get all their values.
      .map(obj => obj.fields.map(_._2))
      .map {
        // Don't fail on validation error, but mention it.
        _.flatMap { value =>
          value.validate[CountryFeeds] match {
            case JsSuccess(v, _) =>
              Some(v)
            case JsError(_) =>
              log.error(s"CountryFeeds did not validate: $value")
              None
          }
        }.map(_.JSON) // We only care about the JSON feeds for now, but XML and CSV are also available.
        // TODO : CSV feeds are a lot smaller (e.g., 29.9MB vs. 85.2MB gzipped and 127.1MB vs 1.45GB uncompressed!)
      }
  }

  private def fetchFeedData(url: String): Future[Source[ByteString, _]] = {
    log.debug(url)
    wsClient
      .url(url)
      .get()
      .map { r =>
        log.debug(s"${r.status} ${r.statusText} ${r.headers}")
        r.bodyAsSource
      }
  }

  private def processFeedData(source: Source[ByteString, _],
                              count: AtomicLong,
                              batchSize: Int = 100,
                              parallelism: Int = 1): (KillSwitch, Future[Done]) = {
    val unzippedContent = JSONFeed(source, "events")
    // discard
    log.debug(s"valuesBeforeStreamField: ${unzippedContent.valuesBeforeStreamField()}")
    unzippedContent
      .streamFieldContents()
      .collect({ case o: JsObject => o })
      .alsoTo(Sink.foreach(_ => count.incrementAndGet))
      .viaMat(KillSwitches.single)(Keep.right)
      .grouped(batchSize)
      .mapAsyncUnordered(parallelism) { events =>
        service.bulkUpsert(events)
      }
      .toMat(Sink.ignore)(Keep.both)
      .run()
  }
}
