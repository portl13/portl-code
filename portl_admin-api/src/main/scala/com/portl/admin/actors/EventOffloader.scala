package com.portl.admin.actors
import akka.Done
import akka.actor.{Actor, FSM}
import akka.stream.{ActorAttributes, Materializer, Supervision}
import com.portl.admin.models.internal
import com.portl.admin.services.integrations.PORTLService
import com.portl.commons.models.StoredEvent
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.json.{JsObject, Json}
import reactivemongo.akkastream.cursorProducer
import reactivemongo.api.ReadPreference
import reactivemongo.api.commands.WriteConcern
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

object EventOffloader {

  private case object Finished
  private case object Failed

  trait Data
  case object EmptyData extends Data

  sealed trait State
  case object Stopped extends State
  case object Running extends State
}

class EventOffloader @Inject()(service: PORTLService,
                               implicit val materializer: Materializer,
                               implicit val executionContext: ExecutionContext)
    extends Actor
    with FSM[EventOffloader.State, EventOffloader.Data] {
  import EventOffloader._
  import SharedMessages._

  def cutoffDate: String = DateTime.now.minusWeeks(2).toString(internal.Event.localDateFormat)

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      goto(Running)
  }

  when(Running) {
    case Event(Finished, _) =>
      goto(Stopped)
  }

  whenUnhandled {
    case Event(QueryStatus, _) =>
      stay replying currentStatus
  }

  onTransition {
    case (Stopped, x) if x != Stopped =>
      service.countEvents.map(c =>
        log.info("offloading events before {} from searchable collection of {} events", cutoffDate, c))
    case (x, Stopped) if x != Stopped =>
      service.countEvents.map(c => log.info("offloading events stopped with {} remaining searchable events", c))
  }

  onTransition {
    case Stopped -> Running =>
      offloadHistoricalEvents().foreach { _ =>
        self ! Finished
      }
  }

  def currentStatus: JsObject = {
    val serializedData: JsObject = stateData match {
      case EmptyData => JsObject.empty
    }
    Json.obj(
      "state" -> stateName.toString,
      "data" -> serializedData
    )
  }

  private def loggingResumeDecider: Supervision.Decider = {
    e: Throwable =>
      log.error(e.getMessage)
      Supervision.Resume
  }

  private def offloadHistoricalEvents(): Future[Done] = {
    val historicalQuery = Json.obj("localStartDate" -> Json.obj("$lt" -> cutoffDate))
    for {
      sourceCollection <- service.collection(service.EVENTS)
      targetCollection <- service.collection(service.HISTORICAL_EVENTS)
      result <- sourceCollection
        .find[JsObject, JsObject](historicalQuery, None)
        .batchSize(1000)
        .cursor[StoredEvent](ReadPreference.secondaryPreferred)
        .bulkSource()
        .map(_.toIterable)
        .mapAsync(1) { events =>
          log.debug("offloading batch of {} events", events.size)
          // yield ids of successfully inserted objects so they can be removed from source collection
          for {
            writeResult <- targetCollection.insert(ordered = false).many(events)
          } yield {
            if (writeResult.ok) {
              log.debug("WriteResult ok")
              events.map(_.id)
            } else {
              log.error("offloading writeResult error: {}", writeResult.errmsg)
              Seq.empty
            }
          }
        }.withAttributes(ActorAttributes.supervisionStrategy(loggingResumeDecider))
        .mapAsync(1) { insertedEventIds =>
          log.debug("deleting {} events after offload", insertedEventIds.size)
          sourceCollection.delete(ordered = false).one(service.queryByObjectIds(insertedEventIds))
        }.withAttributes(ActorAttributes.supervisionStrategy(Supervision.resumingDecider))
        .runForeach { deleteResult =>
          log.debug("deleted {} events after offload", deleteResult.n)
        }
    } yield result
  }

}
