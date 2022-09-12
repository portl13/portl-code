package com.portl.api.models.controller

import play.api.libs.json.Json

case class VenuesByKeywordResponse(
    keyword: String,
    items: List[VenueWithEventsResponse],
    totalCount: Int,
    page: Int,
    pageSize: Int
)

object VenuesByKeywordResponse {
  implicit val venuesByKeywordResponseFormat = Json.format[VenuesByKeywordResponse]
}
