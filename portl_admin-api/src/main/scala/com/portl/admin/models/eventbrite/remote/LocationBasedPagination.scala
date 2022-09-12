package com.portl.admin.models.eventbrite.remote

import play.api.libs.json.{Format, Json}

case class LocationBasedPagination(
    object_count: Int,
    page_number: Int,
    page_size: Int,
    page_count: Int,
    has_more_items: Boolean
)

object LocationBasedPagination {
  implicit val searchResultFormat: Format[LocationBasedPagination] = Json.format[LocationBasedPagination]
}
