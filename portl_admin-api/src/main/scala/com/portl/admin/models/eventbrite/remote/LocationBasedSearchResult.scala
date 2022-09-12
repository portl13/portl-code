package com.portl.admin.models.eventbrite.remote

import play.api.libs.json.{Format, JsObject, Json}

case class LocationBasedSearchResult(pagination: LocationBasedPagination, events: List[JsObject], location: Location)

object LocationBasedSearchResult {
  implicit val searchResultFormat: Format[LocationBasedSearchResult] = Json.format[LocationBasedSearchResult]
}
