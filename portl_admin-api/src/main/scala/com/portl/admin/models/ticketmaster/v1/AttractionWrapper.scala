package com.portl.admin.models.ticketmaster.v1

import play.api.libs.json.{Json, OFormat}

case class AttractionWrapper(attraction: Attraction)

object AttractionWrapper {
  implicit val attractionFormat: OFormat[AttractionWrapper] = Json.format[AttractionWrapper]
}
