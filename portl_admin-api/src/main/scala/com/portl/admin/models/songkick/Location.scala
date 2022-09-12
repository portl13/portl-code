package com.portl.admin.models.songkick

import play.api.libs.json._

case class Location(
    lng: Double, // present, but maybe null
    city: String,
    lat: Double // present, but maybe null
)

object Location {
  implicit val format: OFormat[Location] = Json.format[Location]
}
