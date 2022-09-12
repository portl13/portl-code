package com.portl.admin.services.integrations

import akka.stream.Materializer
import com.portl.admin.models.ticketfly.Event
import com.portl.admin.models.ticketfly.remote.SearchResult
import com.portl.admin.services.LocalDataService
import com.portl.admin.services.background.BackgroundTaskService
import com.portl.commons.models.EventSource
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.Configuration
import play.api.libs.json._
import play.api.libs.ws.{WSClient, WSRequest, WSRequestExecutor, WSRequestFilter}
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import reactivemongo.api.ReadPreference
import reactivemongo.api.commands.UpdateWriteResult
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

class TicketflyService @Inject()(@NamedDatabase("ticketfly") val reactiveMongoApi: ReactiveMongoApi,
                                 implicit val executionContext: ExecutionContext,
                                 implicit val materializer: Materializer,
                                 ws: WSClient,
                                 backgroundTaskService: BackgroundTaskService,
                                 localDataService: LocalDataService,
                                 configuration: Configuration)
    extends MappableEventStorageService[Event] {

  override val eventSource: EventSource = EventSource.Ticketfly
  val collectionName = "events"
  override implicit val format: OFormat[Event] = Event.format

  override def eventsSinceSelector(since: DateTime): JsObject =
    // 2007-12-03
    Json.obj("startDate" -> Json.obj("$gte" -> since.toString("yyyy-MM-dd")))

  class UserAgentSpoofingFilter extends WSRequestFilter {
    override def apply(executor: WSRequestExecutor): WSRequestExecutor = {
      WSRequestExecutor(r => executor(r.addHttpHeaders("User-Agent" -> localDataService.nextUserAgent)))
    }
  }

  def getRawData(params: Map[String, String], page: Int): Future[JsValue] = {
    var request: WSRequest = ws
      .url("http://www.ticketfly.com/api/events/upcoming.json")
      // POR-381 Spoof the user agent. Default user agent "User-Agent: AHC/2.0" results in RemotelyClosedException.
      .withRequestFilter(new UserAgentSpoofingFilter)
      .addHttpHeaders("Accept" -> "application/json")
      .addQueryStringParameters("orgId" -> 1.toString)
      .addQueryStringParameters("fields" -> Event.requiredFields.mkString(","))
      .addQueryStringParameters("pageNum" -> page.toString)
    for ((k, v) <- params) request = request.addQueryStringParameters(k -> v)
    log.debug(request.uri.toString)
    request.get().map(_.json)
  }

  def getData(params: Map[String, String], page: Int): Future[SearchResult] = {
    for {
      js <- getRawData(params, page)
    } yield js.as[SearchResult]
  }

  def bulkUpsert(events: List[JsObject]): Future[UpdateWriteResult] = {
    val IMPOSSIBLE_ID = -1
    val (withId, noId) = events.partition(e => (e \ "id").validate[Int].isSuccess)
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
}
