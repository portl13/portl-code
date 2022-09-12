package com.portl.admin.services.integrations

import akka.stream.Materializer
import akka.stream.scaladsl.Source
import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models.EventSource
import org.joda.time.DateTime
import org.slf4j.Logger
import play.api.libs.json._
import reactivemongo.akkastream.{State, cursorProducer}
import reactivemongo.api.{Cursor, ReadConcern, ReadPreference}
import reactivemongo.play.json.compat._
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.{ExecutionContext, Future}

/**
  * A source of events mappable to models.internal.Event.
  *
  * @tparam E The concrete Event type of the underlying data source.
  *           Necessary so this trait can validate incoming js objects as that type.
  */
trait MappableEventSource[E <: MapsToPortlEntity[internal.Event]] {
  implicit def collection: Future[JSONCollection]
  implicit val executionContext: ExecutionContext
  implicit val materializer: Materializer
  implicit val format: OFormat[E]
  protected val log: Logger

  def eventSource: EventSource
  def projection: JsObject = JsObject.empty
  def eventsSinceSelector(since: DateTime): JsObject

  def upcomingEventsStartDate: DateTime = DateTime.now().minusDays(1)

  def countEvents(selector: Option[JsObject]): Future[Long] = {
    collection.flatMap(_.count(selector, None, 0, None, ReadConcern.Local))
  }

  def countAllEvents: Future[Long] = {
    countEvents(None)
  }

  def countUpcomingEvents: Future[Long] = {
    countEvents(Some(eventsSinceSelector(upcomingEventsStartDate)))
  }

  def allEventsSource: Future[Source[E, Future[State]]] = {
    for {
      c <- collection
    } yield {
      c.find(JsObject.empty, Some(projection))
        // QueryFlags.Exhaust?
        // limit response length (projection, batch size)
        .cursor[JsObject](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson(event).toString, e)
        }))
        .map[JsResult[E]](_.validate[E])
        .filter({
          case JsSuccess(_, _) => true
          case JsError(errors) =>
            log.debug(errors.mkString(" "))
            false
        })
        .collect { case JsSuccess(e, _) => e }
    }
  }

  /**
    * Yields all upcoming events from this data store.
    *
    * Upcoming events, for the purposes of aggregation, include all those starting yesterday, today or in the future.
    * This is a bit of a misnomer, but the reasoning is we want to catch any late-breaking changes to events that are
    * just about to start or have already started (POR-871). Going back an extra day allows for timezone slop.
    */
  def upcomingEventsSource: Future[Source[E, Future[State]]] = {
    for {
      c <- collection
    } yield {
      c.find(eventsSinceSelector(upcomingEventsStartDate), Some(projection))
        // QueryFlags.Exhaust?
        // limit response length (projection, batch size)
        .cursor[JsObject](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson(event).toString, e)
        }))
        .map[JsResult[E]](_.validate[E])
        .filter({
          case JsSuccess(_, _) => true
          case JsError(errors) =>
            log.debug(errors.mkString(" "))
            false
        })
        .collect { case JsSuccess(e, _) => e }
    }
  }
}
