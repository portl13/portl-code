package com.portl.admin.models.eventbrite.remote

import play.api.libs.json.{Format, Json}

case class AugmentedLocation(country: String, region: String)

object AugmentedLocation {
  implicit val searchResultFormat: Format[AugmentedLocation] = Json.format[AugmentedLocation]
}
