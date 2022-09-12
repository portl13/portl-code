package com.portl.admin.models.ticketmaster.remote

import play.api.libs.json.{Format, Json}

/**
  * A ticketmaster discovery v2 API response.
  *
  * "_embedded": { "events": List(Event) },
  * "_links": { ... },
  * "page": Pagination(...)
  */
case class SearchResult(
    // _embedded is missing if no results match the search or if page.page >= page.totalPages
    _embedded: Option[EmbeddedEvents],
    page: Pagination
)

object SearchResult {
  implicit val resultsFormat: Format[SearchResult] = Json.format[SearchResult]
}
