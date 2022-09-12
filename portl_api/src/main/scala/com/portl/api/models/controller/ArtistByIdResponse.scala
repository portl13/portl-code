package com.portl.api.models.controller

import play.api.libs.json._

case class ArtistByIdResponse(
    identifier: String,
    artist: ArtistP,
    events: List[EventP]
)

object ArtistByIdResponse {
  implicit val artistByIdResponseFormat = Json.format[ArtistByIdResponse]
}