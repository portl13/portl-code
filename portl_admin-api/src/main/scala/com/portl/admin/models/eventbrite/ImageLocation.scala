package com.portl.admin.models.eventbrite

import play.api.libs.json.{Format, Json}

case class ImageLocation(url: String, width: Option[Int], height: Option[Int])

object ImageLocation {
  implicit val searchResultFormat: Format[ImageLocation] = Json.format[ImageLocation]
}
