package com.portl.api.models.controller

import play.api.libs.json.Json

case class ArtistsResponse(
    totalCount: Long,
    artists: List[ArtistP]
)

object ArtistsResponse {
  implicit val artistsResponseFormat = Json.format[ArtistsResponse]
}
