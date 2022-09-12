package com.portl.admin.models.songkick.remote

import play.api.libs.json.{Format, Json}

case class SearchResult(
    resultsPage: Page
)

object SearchResult {
  implicit val resultsFormat: Format[SearchResult] = Json.format[SearchResult]
}
