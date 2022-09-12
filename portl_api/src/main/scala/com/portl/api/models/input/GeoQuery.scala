package com.portl.api.models.input

import play.api.libs.json.Json

case class GeoQuery(lat: Double, lng: Double, page: Int, pageSize: Int, maxDistance: Option[Double])

object GeoQuery {
  implicit val geoQueryFormat = Json.format[GeoQuery]
}