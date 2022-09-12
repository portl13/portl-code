package com.portl.api.models.controller

import play.api.libs.json.Json

case class EventsResponse(totalCount: Int, events: List[EventP])

object EventsResponse {
  implicit val eventsResponseFormat = Json.format[EventsResponse]
}