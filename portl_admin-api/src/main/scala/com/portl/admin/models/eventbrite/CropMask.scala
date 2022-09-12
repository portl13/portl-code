package com.portl.admin.models.eventbrite

import play.api.libs.json.{Format, Json}

case class CropMask(top_left: Coordinate, width: Int, height: Int)

object CropMask {
  implicit val searchResultFormat: Format[CropMask] = Json.format[CropMask]
}
