package com.portl.admin.models.eventbrite.remote

import play.api.libs.json.{Format, JsObject, Json}

case class ContinuationBasedSearchResult(pagination: ContinuationBasedPagination, events: List[JsObject])

object ContinuationBasedSearchResult {
  implicit val searchResultFormat: Format[ContinuationBasedSearchResult] = Json.format[ContinuationBasedSearchResult]
}
