package com.portl.api.models.controller

import play.api.libs.json._

case class ArtistWithEventsResponse(
    artist: ArtistP,
    events: List[EventP]
)

object ArtistWithEventsResponse {
  implicit val artistWithEventsResultFormat = Json.format[ArtistWithEventsResponse]
}