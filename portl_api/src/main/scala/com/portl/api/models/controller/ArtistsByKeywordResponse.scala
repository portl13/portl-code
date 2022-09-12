package com.portl.api.models.controller

import play.api.libs.json.Json

case class ArtistsByKeywordResponse(
    keyword: String,
    items: List[ArtistWithEventsResponse],
    totalCount: Int,
    page: Int,
    pageSize: Int
)

object ArtistsByKeywordResponse {
  implicit val artistsWithEventsResponseFormat = Json.format[ArtistsByKeywordResponse]
}
