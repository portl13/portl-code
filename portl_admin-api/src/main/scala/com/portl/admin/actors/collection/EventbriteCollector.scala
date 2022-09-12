package com.portl.admin.actors.collection

import akka.actor.{Actor, FSM}
import com.portl.admin.models.eventbrite.remote.ContinuationBasedSearchResult
import com.portl.admin.services.integrations.EventbriteService
import javax.inject.Inject
import play.api.Configuration
import play.api.libs.json.{JsObject, Json}
import play.api.libs.ws.{WSClient, WSRequest}

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

object EventbriteCollector {
  // internal messages
  private case class GotPage(page: ContinuationBasedSearchResult)
  private case object FinishedPage
  private case object Failed

  trait Data
  case object EmptyData extends Data
  case class FetchingPageData(count: Int, previousPage: Option[ContinuationBasedSearchResult]) extends Data
  case class ProcessingPageData(count: Int, page: ContinuationBasedSearchResult) extends Data

  sealed trait State
  case object Stopped extends State
  case object FetchingPage extends State
  case object ProcessingPage extends State
}

class EventbriteCollector @Inject()(service: EventbriteService,
                                    wsClient: WSClient,
                                    configuration: Configuration,
                                    implicit val executionContext: ExecutionContext)
    extends Actor
    with FSM[EventbriteCollector.State, EventbriteCollector.Data] {
  import EventbriteCollector._
  import com.portl.admin.actors.SharedMessages._

  private val apiToken = configuration.get[String]("com.portl.integrations.eventbrite.token")

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      goto(FetchingPage) using FetchingPageData(0, None)
  }

  when(FetchingPage) {
    case Event(GotPage(page), FetchingPageData(count, _)) =>
      goto(ProcessingPage) using ProcessingPageData(count, page)
  }

  when(ProcessingPage) {
    case Event(FinishedPage, ProcessingPageData(count, page)) if page.pagination.has_more_items =>
      goto(FetchingPage) using FetchingPageData(count + page.events.length, Some(page))
    case Event(FinishedPage, _) =>
      log.info(s"{} collection finished", service.eventSource.toString)
      goto(Stopped)
  }

  whenUnhandled {
    case Event(Failed, _) =>
      goto(Stopped)
    case Event(Stop, _) =>
      log.info("{} collection intentionally stopped", service.eventSource.toString)
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

  onTransition {
    case _ -> FetchingPage =>
      nextStateData match {
        case FetchingPageData(_, previousPage) =>
          fetchPage(previousPage.map(_.pagination.continuation)).onComplete {
            case Success(page) =>
              self ! GotPage(page)
            case Failure(exception) =>
              log.error(exception, "{} collection failed", service.eventSource.toString)
              self ! Failed
          }
        case d => log.error("{} collection transition with unexpected state data {}", service.eventSource.toString, d)
      }
    case FetchingPage -> ProcessingPage =>
      nextStateData match {
        case ProcessingPageData(_, page) =>
          service.bulkUpsert(page.events).onComplete {
            case Success(_) =>
              self ! FinishedPage
            case Failure(exception) =>
              log.error(exception, "{} collection failed", service.eventSource.toString)
              self ! Failed
          }
        case d => log.error("{} collection transition with unexpected state data {}", service.eventSource.toString, d)
      }
  }

  initialize()

  def currentStatus: JsObject = {
    // Note: IntelliJ highlights the `->` red, but it compiles fine. IDE must be confused about the FSM.`->` extractor.
    val serializedData: JsObject = stateData match {
      case EmptyData => JsObject.empty
      case FetchingPageData(count, previousPage) =>
        Json.obj(
          "count" -> count,
          "previousPage" -> previousPage.map(_.pagination),
        )
      case ProcessingPageData(count, page) =>
        Json.obj(
          "count" -> count,
          "currentPage" -> page.pagination,
        )
    }
    Json.obj(
      "state" -> stateName.toString,
      "data" -> serializedData
    )
  }

  private def fetchPage(continuation: Option[String] = None): Future[ContinuationBasedSearchResult] = {
    var request: WSRequest = wsClient
      .url("https://www.eventbriteapi.com/v3/events/")
      .addHttpHeaders("Accept" -> "*/*")
      .addQueryStringParameters("expand" -> "venue,category")
      .addQueryStringParameters("token" -> apiToken)
      .addQueryStringParameters("country" -> "US")

    continuation.foreach { continuationString =>
      request = request.addQueryStringParameters("continuation" -> continuationString)
    }
    log.debug(request.uri.toString)
    request.get().map(_.json.as[ContinuationBasedSearchResult])
  }
}
