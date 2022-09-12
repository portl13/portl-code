package com.portl.api.models.controller

import play.api.libs.json.Json

case class VenuesResponse(
    totalCount: Long,
    venues: List[VenueP]
)

object VenuesResponse {
  implicit val venuesResponseFormat = Json.format[VenuesResponse]
}
