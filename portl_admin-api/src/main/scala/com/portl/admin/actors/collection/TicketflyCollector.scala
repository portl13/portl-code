package com.portl.admin.actors.collection
import java.util.concurrent.atomic.AtomicLong

import akka.actor.{Actor, FSM}
import com.portl.admin.models.ticketfly
import com.portl.admin.models.ticketfly.remote.SearchResult
import com.portl.admin.services.LocalDataService
import com.portl.admin.services.integrations.TicketflyService
import javax.inject.Inject
import play.api.libs.json.{JsObject, JsValue, Json}
import play.api.libs.ws.{WSClient, WSRequest, WSRequestExecutor, WSRequestFilter}

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

object TicketflyCollector {
  // internal messages
  private case class GotPage(page: SearchResult)
  private case object FinishedPage
  private case object Failed

  trait Data
  case object EmptyData extends Data
  case class FetchingPageData(pageNum: Int, previousPage: Option[SearchResult]) extends Data
  case class ProcessingPageData(page: SearchResult) extends Data

  sealed trait State
  case object Stopped extends State
  case object FetchingPage extends State
  case object ProcessingPage extends State
}

class TicketflyCollector @Inject()(service: TicketflyService,
                                   wsClient: WSClient,
                                   localDataService: LocalDataService,
                                   implicit val executionContext: ExecutionContext)
    extends Actor
    with FSM[TicketflyCollector.State, TicketflyCollector.Data] {
  import TicketflyCollector._
  import com.portl.admin.actors.SharedMessages._

  private val count = new AtomicLong(0)

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      log.info("{} collection started", service.eventSource.toString)
      count.set(0)
      goto(FetchingPage) using FetchingPageData(1, None)
  }

  when(FetchingPage) {
    case Event(GotPage(page), _) =>
      goto(ProcessingPage) using ProcessingPageData(page)
  }

  when(ProcessingPage) {
    case Event(FinishedPage, ProcessingPageData(page)) if page.pageNum < page.totalPages =>
      goto(FetchingPage) using FetchingPageData(page.pageNum + 1, Some(page))
    case Event(FinishedPage, _) =>
      log.info("{} collection finished", service.eventSource.toString)
      goto(Stopped)
  }

  whenUnhandled {
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
        case FetchingPageData(pageNum, _) =>
          getData(pageNum).onComplete {
            case Success(page) =>
              log.debug("{} received page", service.eventSource.toString)
              self ! GotPage(page)
            case Failure(exception) =>
              log.error(exception, "{} collection failed", service.eventSource.toString)
              self ! Failed
          }
        case d => log.error("{} collection transition with unexpected state data {}", service.eventSource.toString, d)
      }
    case FetchingPage -> ProcessingPage =>
      nextStateData match {
        case ProcessingPageData(page) =>
          service.bulkUpsert(page.events).onComplete {
            case Success(_) =>
              count.addAndGet(page.events.length)
              log.debug("{} processed page", service.eventSource.toString)
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
      case FetchingPageData(pageNum, previousPage) =>
        Json.obj(
          "count" -> count.get,
          "page" -> pageNum,
          "totalPages" -> previousPage.map(_.totalPages),
          "totalResults" -> previousPage.map(_.totalResults))
      case ProcessingPageData(page) =>
        Json.obj(
          "count" -> count.get,
          "page" -> page.pageNum,
          "totalPages" -> page.totalPages,
          "totalResults" -> page.totalResults)
    }
    Json.obj(
      "state" -> stateName.toString,
      "data" -> serializedData
    )
  }

  class UserAgentSpoofingFilter extends WSRequestFilter {
    override def apply(executor: WSRequestExecutor): WSRequestExecutor = {
      WSRequestExecutor(r => executor(r.addHttpHeaders("User-Agent" -> localDataService.nextUserAgent)))
    }
  }

  private def getData(page: Int): Future[SearchResult] = {
    val request: WSRequest = wsClient
      .url("http://www.ticketfly.com/api/events/upcoming.json")
      // POR-381 Spoof the user agent. Default user agent "User-Agent: AHC/2.0" results in RemotelyClosedException.
      .withRequestFilter(new UserAgentSpoofingFilter)
      .addHttpHeaders("Accept" -> "application/json")
      .addQueryStringParameters("orgId" -> 1.toString)
      .addQueryStringParameters("fields" -> ticketfly.Event.requiredFields.mkString(","))
      .addQueryStringParameters("pageNum" -> page.toString)
    log.debug(request.uri.toString)
    request.get().map(_.json.as[SearchResult])
  }
}
