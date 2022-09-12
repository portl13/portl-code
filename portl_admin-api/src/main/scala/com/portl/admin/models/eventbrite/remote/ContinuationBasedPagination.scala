package com.portl.admin.models.eventbrite.remote

import play.api.libs.json.{Format, Json}

case class ContinuationBasedPagination(
    page_number: Int,
    page_size: Int,
    has_more_items: Boolean,
    continuation: String
)

object ContinuationBasedPagination {
  implicit val searchResultFormat: Format[ContinuationBasedPagination] = Json.format[ContinuationBasedPagination]
}
