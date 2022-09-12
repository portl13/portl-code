package com.portl.admin.actors.aggregation

import akka.Done
import akka.actor.{Actor, FSM}
import akka.stream.{KillSwitch, KillSwitches, Materializer}
import akka.stream.scaladsl.{Keep, Source}
import com.google.inject.assistedinject.Assisted
import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.admin.services.integrations.{PORTLService, MappableEventStorageService}
import com.portl.admin.streams.{Counter, CounterFlow}
import javax.inject.Inject
import play.api.libs.json._

import scala.concurrent.Future
import scala.util.{Failure, Success}

object PORTLEventAggregator {
  sealed trait State
  case object Stopped extends State
  case object Starting extends State
  case object Running extends State

  sealed trait Data
  case object EmptyData extends Data
  case class RunningData(killSwitch: KillSwitch,
                         counter: Counter,
                         startingAvailableCount: Long,
                         startingPORTLCount: Long)
      extends Data

  // messages sent from outside
  case object Start
  case object Stop
  case object QueryStatus

  // internal messages
  private case class GotCounts(startingAvailableCount: Long, startingPORTLCount: Long)
  private case object Failed
  private case object Finished

  private case object IntentionallyStoppedException extends Exception

  trait Factory {
    def apply(service: MappableEventStorageService[_ <: MapsToPortlEntity[internal.Event]]): Actor
  }
}

class PORTLEventAggregator @Inject()(
    portlService: PORTLService,
    @Assisted service: MappableEventStorageService[_ <: MapsToPortlEntity[internal.Event]],
    implicit val materializer: Materializer)
    extends Actor
    with FSM[PORTLEventAggregator.State, PORTLEventAggregator.Data] {
  import PORTLEventAggregator._
  import context.dispatcher

  // TODO resume
  // TODO better stats

  startWith(Stopped, EmptyData)
  when(Stopped) {
    case Event(Start, _) =>
      val fAvailable = service.countUpcomingEvents
      val fPortl = portlService.countEvents
      for {
        availableCount <- fAvailable
        portlCount <- fPortl
      } yield self ! GotCounts(availableCount, portlCount)
      goto(Starting)
  }

  when(Starting) {
    case Event(GotCounts(startingAvailableCount, startingPORTLCount), _) =>
      log.info(
        "{} aggregation started. {} events available to process, {} in PORTL db",
        service.eventSource.toString,
        startingAvailableCount,
        startingPORTLCount)
      val (ks, counter, futureDone) = start()
      futureDone.onComplete {
        case Success(_) =>
          log.info("{} aggregation finished", service.eventSource.toString)
          self ! Finished
        case Failure(IntentionallyStoppedException) =>
          log.info("{} aggregation intentionally stopped", service.eventSource.toString)
        case Failure(exception) =>
          log.error(exception, "{} aggregation failed", service.eventSource.toString)
          self ! Failed
      }
      goto(Running) using RunningData(ks, counter, startingAvailableCount, startingPORTLCount)
  }

  when(Running) {
    case Event(Stop, RunningData(killSwitch, _, _, _)) =>
      killSwitch.abort(IntentionallyStoppedException)
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
    case Running -> Stopped =>
      stateData match {
        case RunningData(_, counter, _, _) =>
          for {
            portlCount <- portlService.countEvents
          } yield
            log.info(
              "{} aggregation processed {} events, {} in PORTL db",
              service.eventSource.toString,
              counter.get,
              portlCount)
        case d => log.error("{} aggregation stopped with unexpected state data {}", service.eventSource.toString, d)
      }
  }

  initialize()

  def currentStatus: JsObject = stateData match {
    case EmptyData => Json.obj("state" -> stateName.toString)
    case RunningData(_, counter, startingAvailableCount, startingPORTLCount) =>
      Json.obj(
        "state" -> stateName.toString,
        "count" -> counter.get,
        "startingAvailableCount" -> startingAvailableCount,
        "startingPORTLCount" -> startingPORTLCount)
  }

  private def start(): (KillSwitch, Counter, Future[Done]) = {
    val source = Source.fromFutureSource(service.upcomingEventsSource)
    val ((killSwitch: KillSwitch, counter: Counter), done: Future[Done]) = source
      .viaMat(KillSwitches.single)(Keep.right)
      .viaMat(CounterFlow[MapsToPortlEntity[internal.Event]])(Keep.both)
      .toMat(portlService.storeEventsSink())(Keep.both)
      .run()
    (killSwitch, counter, done)
  }
}
