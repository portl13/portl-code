package com.portl.api.models.controller

import play.api.libs.json.Json

case class VenueWithEventsResponse(
    identifier: String,
    venue: VenueP,
    events: List[EventP]
)

object VenueWithEventsResponse {
  implicit val venueResultFormat = Json.format[VenueWithEventsResponse]
}
