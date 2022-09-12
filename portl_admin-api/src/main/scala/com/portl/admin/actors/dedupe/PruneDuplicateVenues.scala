package com.portl.admin.actors.dedupe

import akka.Done
import akka.actor.{Actor, ActorLogging, FSM}
import akka.stream.scaladsl.{Keep, Sink, Source}
import akka.stream.{KillSwitch, KillSwitches, Materializer}
import com.portl.admin.actors.SharedMessages
import com.portl.admin.services.integrations.PORTLService
import javax.inject.Inject
import play.api.libs.json.{JsObject, Json}
import play.api.libs.ws.WSClient
import reactivemongo.play.json.compat._

import scala.concurrent.Future
import scala.concurrent.duration._
import scala.util.{Failure, Success}

object PruneDuplicateVenues {
  // messages
  private case object Finished
  private case object Failed

  trait Data
  case object EmptyData extends Data
  case class RunningData(ks: KillSwitch) extends Data

  sealed trait State
  case object Stopped extends State
  case object Running extends State
}

class PruneDuplicateVenues @Inject()(
                                      portlService: PORTLService,
                                      ws: WSClient,
                                      implicit val materializer: Materializer)
  extends Actor with FSM[PruneDuplicateVenues.State, PruneDuplicateVenues.Data] with ActorLogging {

  import PruneDuplicateVenues._
  import SharedMessages._
  import context._

  implicit val timeout: akka.util.Timeout = 5.seconds

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      val (ks, futureDone) = pruneDuplicateVenuesSource()
      futureDone.onComplete {
        case Success(_) =>
          log.info("Prune duplicate venues finished")
          self ! Finished
        case Failure(exception) =>
          log.error(exception, "Prune duplicate venues failed")
          self ! Failed
      }
      goto(Running) using RunningData(ks)
  }

  when(Running) {
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

  def currentStatus: JsObject = {
    val serializedData: JsObject = JsObject.empty
    Json.obj(
      "state" -> stateName.toString,
      "data" -> serializedData
    )
  }

  private def pruneDuplicateVenuesSource(): (KillSwitch, Future[Done]) = {
    val futureSource = portlService.pruneDuplicateVenues(None)

    val source = Source.fromFuture(futureSource)

    val (killSwitch: KillSwitch, done: Future[Done]) = source
      .viaMat(KillSwitches.single)(Keep.right)
      .mapAsync(1)(_ => Future(Done))
      .toMat(Sink.foreach(r => log.debug(s"processAllPruneVenues: $r")))(Keep.both)
      .run()
    (killSwitch, done)
  }
}
