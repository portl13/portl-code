package com.portl.api.models.input

import play.api.libs.json.{Json, OFormat}

case class NameWithLocationQuery(
    name: String,
    location: Option[Location],
    maxDistanceMiles: Option[Double] = None,
    page: Int,
    pageSize: Int
  )

object NameWithLocationQuery {
  implicit val nameQueryFormat: OFormat[NameWithLocationQuery] = Json.format[NameWithLocationQuery]
}
