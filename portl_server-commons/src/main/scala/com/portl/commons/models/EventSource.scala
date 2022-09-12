package com.portl.commons.models

import enumeratum.{Enum, EnumEntry}
import play.api.libs.json.Reads.constraints
import play.api.libs.functional.syntax._
import play.api.libs.json._

sealed abstract class EventSource extends EnumEntry

object EventSource extends Enum[EventSource] {
  val values = findValues

  case object PortlServer extends EventSource
  case object Ticketmaster extends EventSource
  case object Facebook extends EventSource
  case object Eventbrite extends EventSource
  case object Ticketfly extends EventSource
  case object Eventful extends EventSource
  case object Songkick extends EventSource
  case object Meetup extends EventSource
  case object Bandsintown extends EventSource

  implicit val eventSourceFormat: Format[EventSource] =
    new Format[EventSource] {
      override def writes(es: EventSource): JsValue = {
        JsNumber(EventSource.indexOf(es))
      }

      override def reads(json: JsValue): JsResult[EventSource] = {
        __.read[Int](constraints.verifying[Int](i =>
          0 <= i && i < EventSource.values.length)) andKeep
          __.read[Int].map(EventSource.values(_))
      }.reads(json)
    }
}
