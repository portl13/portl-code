package com.portl.admin.services.integrations

import akka.stream.Materializer
import com.portl.admin.models.backgroundTask.{Task, TaskStatus}
import com.portl.admin.models.songkick.Event
import com.portl.admin.models.songkick.remote.{SearchParams, SearchResult}
import com.portl.admin.services.LocalDataService
import com.portl.admin.services.background.BackgroundTaskService
import com.portl.commons.futures.FutureHelpers
import com.portl.commons.models.base.MongoObjectId
import com.portl.commons.models.{EventSource, Location}
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.json._
import play.api.libs.ws.{WSClient, WSRequest}
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import reactivemongo.api.commands.MultiBulkWriteResult
import reactivemongo.api.Cursor
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future, Promise}

class SongkickService @Inject()(configuration: play.api.Configuration,
                                implicit val executionContext: ExecutionContext,
                                implicit val materializer: Materializer,
                                ws: WSClient,
                                @NamedDatabase("songkick") val reactiveMongoApi: ReactiveMongoApi,
                                localDataService: LocalDataService,
                                backgroundTaskService: BackgroundTaskService)
    extends MappableEventStorageService[Event] {

  private val apiToken = configuration.underlying.getString("com.portl.integrations.songkick.token")

  override val eventSource: EventSource = EventSource.Songkick
  val collectionName = "events"
  override implicit val format: OFormat[Event] = Event.format

  override def eventsSinceSelector(since: DateTime): JsObject =
    // 2007-12-03
    Json.obj("start.date" -> Json.obj("$gte" -> since.toString("yyyy-MM-dd")))

  def getRawData(params: SearchParams): Future[JsValue] = {
    // pages are 1-indexed on this api
    val request: WSRequest = ws
      .url("https://api.songkick.com/api/3.0/events.json")
      .addHttpHeaders("Accept" -> "application/json")
      .addQueryStringParameters("location" -> s"geo:${params.location.latitude},${params.location.longitude}")
      .addQueryStringParameters("apikey" -> apiToken)
      .addQueryStringParameters("page" -> params.page.toString)
    log.debug(request.toString)
    request.get().map(_.json)
  }

  def getData(params: SearchParams): Future[SearchResult] = {
    this.getRawData(params).flatMap { js =>
      val results = js.as[SearchResult]

      results.resultsPage.results.event match {
        case Some(events) =>
          bulkUpsert(events).map(_ => results)
        case None =>
          log.warn(s"got empty events list: $js")
          Future(results)
      }
    }
  }

  def collectSearchResults(location: Location, maxPages: Int = 200): Future[Unit] = {
    // New York has 90 pages today. Set maxPages to some sane number so we can't just spin forever.
    val promise = Promise[Unit]()

    def shouldContinue(response: SearchResult): Boolean = {
      // bail out if we have gotten the last page, hit our maxPages limit, or got an empty page
      val totalPages = (response.resultsPage.totalEntries.toFloat / response.resultsPage.perPage).toInt
      val page = response.resultsPage.page
      if (page >= totalPages) {
        log.debug(
          s"stop collectSearchResults ${location.longitude},${location.latitude}: page $page >= totalPages $totalPages")
        false
      } else if (page >= maxPages) {
        log.debug(
          s"stop collectSearchResults ${location.longitude},${location.latitude}: page $page >= maxPages $maxPages")
        false
      } else if (response.resultsPage.results.event.forall(_.isEmpty)) {
        log.debug(s"stop collectSearchResults ${location.longitude},${location.latitude}: page $page yields no results")
        false
      } else true
    }

    def getRemainingPages(params: SearchParams): Future[Unit] = {
      for {
        searchResult <- getData(params)
      } yield {
        if (shouldContinue(searchResult))
          getRemainingPages(params.copy(page = params.page + 1))
        else
          promise.success(())
      }
    }

    getRemainingPages(SearchParams(location))
    promise.future
  }

  def collectEventsForUSCities(): Future[Unit] = {
    // This took about 2 hours and 6000 requests. TODO : there was some duplication / overlap in cities, can we reduce that?
    val task = Task(
      MongoObjectId.generate,
      TaskStatus.InProgress,
      "Collect Songkick events",
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
    val (withId, noId) = events.partition(e => (e \ "id").validate[Int].isSuccess)
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

  def fetchAllEvents: Future[List[Event]] = {
    collection
      .map {
        _.find[JsObject, JsObject](JsObject.empty, None).cursor[Event]()
      }
      .flatMap(_.collect[List](-1, Cursor.ContOnError[List[Event]]()))
  }
}
