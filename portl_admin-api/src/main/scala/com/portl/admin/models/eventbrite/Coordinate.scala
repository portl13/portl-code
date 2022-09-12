package com.portl.admin.models.eventbrite

import play.api.libs.json.{Format, Json}

case class Coordinate(x: Int, y: Int)

object Coordinate {
  implicit val searchResultFormat: Format[Coordinate] = Json.format[Coordinate]
}
