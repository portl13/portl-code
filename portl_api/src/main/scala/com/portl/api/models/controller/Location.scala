package com.portl.api.models.controller

import com.portl.commons
import play.api.libs.json._

case class Location(longitude: Double, latitude: Double)

object Location {
  implicit val portlLocationFormat: Format[Location] = Json.format[Location]

  def apply(location: commons.models.Location): Location = Location(location.longitude, location.latitude)
}
