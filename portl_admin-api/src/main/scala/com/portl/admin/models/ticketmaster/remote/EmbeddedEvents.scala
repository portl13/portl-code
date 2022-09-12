package com.portl.admin.models.ticketmaster.remote

import play.api.libs.json.{Format, JsObject, Json}

case class EmbeddedEvents(
    events: List[JsObject]
)

object EmbeddedEvents {
  implicit val resultsFormat: Format[EmbeddedEvents] = Json.format[EmbeddedEvents]
}
