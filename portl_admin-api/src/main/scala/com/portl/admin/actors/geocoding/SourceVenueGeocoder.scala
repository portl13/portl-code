package com.portl.admin.actors.geocoding

import akka.pattern.ask
import akka.{Done, NotUsed}
import akka.actor.{Actor, ActorRef, FSM, Props}
import akka.stream.scaladsl.{Keep, Sink, Source}
import akka.stream.{KillSwitch, KillSwitches, Materializer, OverflowStrategy, RateExceededException, ThrottleMode}
import com.google.inject.assistedinject.Assisted
import com.portl.admin.models.internal
import com.portl.admin.models.internal.geocoding.{ForwardGeocodingResult, ReverseGeocodingResult, VenueGeocodingResult}
import com.portl.admin.models.internal.{InvalidEventException, MapsToPortlEntity, Venue}
import com.portl.admin.services.GeocodingResultsService
import com.portl.admin.services.integrations.MappableEventStorageService
import javax.inject.Inject
import play.api.Configuration
import play.api.libs.json._
import play.api.libs.ws.WSClient

import scala.concurrent.duration._
import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}


object SourceVenueGeocoder {
  // internal messages
  private case object Failed
  private case object Finished

  trait Data
  case object EmptyData extends Data
  case class RunningData(ks: KillSwitch) extends Data

  sealed trait State
  case object Stopped extends State
  case object Running extends State

  trait Factory {
    def apply(service: MappableEventStorageService[_ <: MapsToPortlEntity[internal.Event]]): Actor
  }
}


class SourceVenueGeocoder @Inject()(configuration: Configuration,
                                    @Assisted service: MappableEventStorageService[_ <: MapsToPortlEntity[internal.Event]],
                                    val geocodingService: GeocodingResultsService,
                                    val wsClient: WSClient,
                                    implicit val executionContext: ExecutionContext,
                                    implicit val materializer: Materializer)
  extends Actor
    with FSM[SourceVenueGeocoder.State, SourceVenueGeocoder.Data] {
  import SourceVenueGeocoder._
  import com.portl.admin.actors.SharedMessages._
  import context.system

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      val (ks, futureDone) = processAllEvents
      futureDone.onComplete {
        case Success(_) =>
          log.info("{} geocoding finished", service.eventSource.toString)
          self ! Finished
        case Failure(IntentionallyStoppedException) =>
          log.info("{} geocoding intentionally stopped", service.eventSource.toString)
        case Failure(exception) =>
          log.error(exception, "{} geocoding failed", service.eventSource.toString)
          self ! Failed
      }
      goto(Running) using RunningData(ks)
  }

  when(Running) {
    case Event(Stop, RunningData(ks)) =>
      ks.abort(IntentionallyStoppedException)
      goto(Stopped)
    case Event(Finished, _) =>
      goto(Stopped)
  }

  whenUnhandled {
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
        log.info("{} geocoding started with {} existing events", service.eventSource.toString, c))
    case (x, Stopped) if x != Stopped =>
      service.countAllEvents.map(c =>
        log.info("{} geocoding stopped with {} existing events", service.eventSource.toString, c))
  }

  initialize()

  def currentStatus: JsObject = {
    // Note: IntelliJ highlights the `->` red, but it compiles fine. IDE must be confused about the FSM.`->` extractor.
    Json.obj(
      "state" -> stateName.toString,
    )
  }


  private val throttleRequestsPerSecond = configuration.get[Int]("com.portl.integrations.opencage.rateLimitPerSecond")
  private val throttleRequestsPerDay = configuration.get[Int]("com.portl.integrations.opencage.rateLimitPerDay")
  private val geocoder: ActorRef = system.actorOf(Props(classOf[Geocoder], configuration, geocodingService))

  def processAllEvents: (KillSwitch, Future[Done]) = {
    val throttledGeocoder: ActorRef =
      Source
        .actorRef(bufferSize = 100000, OverflowStrategy.fail)
        .throttle(throttleRequestsPerDay, 1.day, throttleRequestsPerDay, ThrottleMode.Enforcing)
        .throttle(throttleRequestsPerSecond, 1.second, throttleRequestsPerSecond, ThrottleMode.Shaping)
        .recover {
          case e: RateExceededException =>
            log.info("throttledGeocoder {}", e)
        }
        .to(Sink.actorRef(geocoder, NotUsed))
        .run()

    val source = Source.fromFutureSource(service.allEventsSource)
    val (killSwitch: KillSwitch, done: Future[Done]) = source
      .viaMat(KillSwitches.single)(Keep.right)
      .map { e =>
        try {
          Some(e.toPortl.venue)
        } catch {
          case _: InvalidEventException => None
        }
      }
      .collect {
        case Some(v) => v
      }
      .mapAsync(1)(geocodeVenue(throttledGeocoder))
      .toMat(Sink.foreach(r => log.debug(s"processAllEvents: $r")))(Keep.both)
      .run()
    (killSwitch, done)
  }


  private def fetchGeocodingResults(throttledGeocoder: ActorRef)(venue: Venue): Future[VenueGeocodingResult] = {
    val forwardGeocodingDispatcher = system.actorOf(Props(classOf[GeocodingDispatcher[ForwardGeocodingResult]], throttledGeocoder, GeocodingDispatcher.Forward))
    val reverseGeocodingDispatcher = system.actorOf(Props(classOf[GeocodingDispatcher[ReverseGeocodingResult]], throttledGeocoder, GeocodingDispatcher.Reverse))
    implicit val timeout: akka.util.Timeout = 30.seconds
    for {
      forward <- (forwardGeocodingDispatcher ? venue).mapTo[Option[ForwardGeocodingResult]]
      reverse <- (reverseGeocodingDispatcher ? venue).mapTo[Option[ReverseGeocodingResult]]
    } yield geocodingService.createEmptyGeocodingResult(venue)
      .copy(forwardGeocodingResult = forward, reverseGeocodingResult = reverse)
  }

  private def lookupOrGeocodeVenue(throttledGeocoder: ActorRef)(venue: Venue): Future[VenueGeocodingResult] = {
    for {
      existingResult <- geocodingService.findByExternalId(venue.externalId)
      result <- existingResult
        .map(Future(_))
        .getOrElse {
          fetchGeocodingResults(throttledGeocoder: ActorRef)(venue)
        }
    } yield result
  }

  private def lookupAndReGeocodeVenue(throttledGeocoder: ActorRef)(venue: Venue): Future[VenueGeocodingResult] = {
    for {
      staleResult <- geocodingService.lookupOrCreateGeocodingResult(venue)
      newResult <- fetchGeocodingResults(throttledGeocoder: ActorRef)(venue)
      result = staleResult.copy(forwardGeocodingResult = newResult.forwardGeocodingResult, reverseGeocodingResult = newResult.reverseGeocodingResult)
      _ <- geocodingService.upsert(result)
    } yield result
  }

  def geocodeVenue(throttledGeocoder: ActorRef)(venue: Venue): Future[VenueGeocodingResult] = {
    for {
      result <- lookupOrGeocodeVenue(throttledGeocoder: ActorRef)(venue)
      _ <- geocodingService.upsert(result)
    } yield result
  }

}
