package com.portl.admin.models.eventbrite.remote

import play.api.libs.json.{Format, Json}

case class Location(
    latitude: String,
    augmented_location: Option[AugmentedLocation],
    within: String,
    longitude: String,
    address: Option[String]
)

object Location {
  implicit val searchResultFormat: Format[Location] = Json.format[Location]
}
