package com.portl.admin.models.ticketmaster.remote

import play.api.libs.json.{Format, Json}

/**
  * Pagination information for a TM events discovery api response.
  *
  * {
  *"size": 200,
  *"totalElements": 150746,
  *"totalPages": 754,
  *"number": 0
  *}
  */
case class Pagination(
    size: Int, // page size
    totalElements: Int,
    totalPages: Int,
    number: Int // current page number
)

object Pagination {
  implicit val format: Format[Pagination] = Json.format[Pagination]
}
