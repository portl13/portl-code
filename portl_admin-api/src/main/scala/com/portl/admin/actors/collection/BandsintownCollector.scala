package com.portl.admin.actors.collection

import java.net.URLEncoder

import akka.Done
import akka.actor.{Actor, FSM}
import akka.stream.{KillSwitch, KillSwitches, Materializer}
import akka.stream.scaladsl.{Keep, Sink}
import com.fasterxml.jackson.core.JsonParseException
import com.portl.admin.models.internal
import com.portl.admin.services.integrations.{BandsintownService, PORTLService}
import com.portl.admin.streams.{Counter, CounterFlow}
import javax.inject.Inject
import play.api.Configuration
import play.api.libs.json._
import play.api.libs.ws.WSClient

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

object BandsintownCollector {
  // internal messages
  private case object Finished
  private case object Failed

  case class Data(killSwitch: Option[KillSwitch], counter: Option[Counter])

  sealed trait State
  case object Stopped extends State
  case object Running extends State
}

/**
  * Collects data from the rest.bandsintown.com API.
  *
  * API docs: https://app.swaggerhub.com/apis/Bandsintown/PublicAPI/3.0.0
  *
  * The API only allows lookups by artist name. We iterate through our artists and look up events for each of them.
  */
class BandsintownCollector @Inject()(configuration: Configuration,
                                     val portlService: PORTLService,
                                     val service: BandsintownService,
                                     val wsClient: WSClient,
                                     implicit val executionContext: ExecutionContext,
                                     implicit val materializer: Materializer)
    extends Actor
    with FSM[BandsintownCollector.State, BandsintownCollector.Data] {
  import BandsintownCollector._
  import com.portl.admin.actors.SharedMessages._

  private val appId = configuration.get[String]("com.portl.integrations.bandsintown.token")

  startWith(Stopped, Data(None, None))

  when(Stopped) {
    case Event(Start, _) =>
      val (ks, counter, futureDone) = start()
      futureDone.onComplete {
        case Success(_) =>
          log.info("{} collection finished: {}", service.eventSource.toString, currentStatus)
          self ! Finished
        case Failure(IntentionallyStoppedException) =>
          log.info("{} collection intentionally stopped", service.eventSource.toString)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! Failed
      }
      goto(Running) using Data(Some(ks), Some(counter))
  }

  when(Running) {
    case Event(Stop, Data(killSwitch, _)) =>
      killSwitch.foreach(_.abort(IntentionallyStoppedException))
      goto(Stopped)
    case Event(Finished, _) =>
      goto(Stopped)
    case Event(Failed, _) =>
      goto(Stopped)
  }

  whenUnhandled {
    case Event(QueryStatus, _) =>
      stay replying currentStatus
  }

  onTransition {
    case Stopped -> x if x != Stopped =>
      service.countAllEvents.map(c =>
        log.info("{} collection started with {} existing events", service.eventSource.toString, c))
    case x -> Stopped if x != Stopped =>
      service.countAllEvents.map(c =>
        log.info("{} collection stopped with {} existing events", service.eventSource.toString, c))
  }

  initialize()

  def currentStatus: JsObject = Json.obj("state" -> stateName.toString, "count" -> stateData.counter.map(_.get))

  private def fetchArtist(artist: internal.Artist): Future[Option[JsObject]] = {
    val request = wsClient
      .url(s"https://rest.bandsintown.com/artists/${URLEncoder.encode(artist.name, "UTF-8")}")
      .addQueryStringParameters("app_id" -> appId)
    log.debug(request.toString)

    val emptyResponseErrorMessages = Seq(
      // {error=Not Found}
      "Unexpected character ('e' (code 101)): was expecting double-quote to start field name",
      // {warn=Not found}
      "Unexpected character ('w' (code 119)): was expecting double-quote to start field name",
      // {message=an internal error occurred}
      "Unexpected character ('m' (code 109)): was expecting double-quote to start field name"
    )

    request.get().map { r =>
      log.debug(s"${r.status} ${r.statusText} ${r.headers}")
      try {
        r.json.asOpt[JsObject]
      } catch {
        case e: JsonParseException if emptyResponseErrorMessages.exists(e.getMessage.startsWith(_)) =>
          log.debug(s"Bandsintown artist not found: ${artist.name}")
          None
        case e: JsonParseException =>
          log.debug("Failed to parse Bandsintown artist response, content follows\n{}", e.getMessage)
          log.debug(r.body)
          None
      }
    }
  }

  private def fetchEvents(artist: internal.Artist): Future[Option[Seq[JsObject]]] = {
    val request = wsClient
      .url(s"https://rest.bandsintown.com/artists/${URLEncoder.encode(artist.name, "UTF-8")}/events")
      .addQueryStringParameters("app_id" -> appId)
    log.debug(request.toString)

    val emptyResponseErrorMessages = Seq(
      // {error=Not Found}
      "Unexpected character ('e' (code 101)): was expecting double-quote to start field name",
      // {warn=Not found}
      "Unexpected character ('w' (code 119)): was expecting double-quote to start field name",
      // {message=an internal error occurred}
      "Unexpected character ('m' (code 109)): was expecting double-quote to start field name"
    )

    request.get().map { r =>
      log.debug(s"${r.status} ${r.statusText} ${r.headers}")
      try {
        r.json.asOpt[Seq[JsObject]]
      } catch {
        case e: JsonParseException if emptyResponseErrorMessages.exists(e.getMessage.startsWith(_)) =>
          log.debug(s"Bandsintown events not found: ${artist.name}")
          None
        case e: JsonParseException =>
          log.debug("Failed to parse Bandsintown events response, content follows\n{}", e.getMessage)
          log.debug(r.body)
          None
      }
    }
  }

  /**
    * Try fetching artist and corresponding event data from API. If we get data for both, upsert them.
    */
  private def processInternalArtist(artist: internal.Artist): Future[Unit] = {
    val artistFuture = fetchArtist(artist)
    val eventFuture = fetchEvents(artist)

    val results: Future[(Option[JsObject], Option[Seq[JsObject]])] = for {
      artistOption <- artistFuture
      eventOption <- eventFuture
    } yield {
      (artistOption, eventOption)
    }

    results.flatMap {
      case (Some(artistObject), Some(eventObjects)) if eventObjects.nonEmpty =>
        service
          .upsertArtist(artistObject)
          .flatMap(_ => service.bulkUpsert(eventObjects))
          .map(_ => ())
      case _ =>
        log.debug("artist or events missing")
        Future.unit
    }
  }

  private def start(): (KillSwitch, Counter, Future[Done]) = {
    val source = portlService.musicArtistsSource()
    val ((killSwitch: KillSwitch, counter: Counter), done: Future[Done]) = source
//      .take(100)
      .viaMat(KillSwitches.single)(Keep.right)
      .viaMat(CounterFlow[internal.Artist])(Keep.both)
      .mapAsync(1)(processInternalArtist)
      .toMat(Sink.ignore)(Keep.both)
      .run()
    (killSwitch, counter, done)
  }

}
