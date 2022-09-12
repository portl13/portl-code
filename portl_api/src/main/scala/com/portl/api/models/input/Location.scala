package com.portl.api.models.input

import play.api.libs.json._
import play.api.libs.functional.syntax._

case class Location(longitude: Double, latitude: Double)

object Location {
  implicit val portlLocationFormat: Format[Location] = new Format[Location] {
    override def writes(loc: Location): JsObject =
      Json.obj("lat" -> loc.latitude, "lng" -> loc.longitude)
    override def reads(json: JsValue): JsResult[Location] =
      (
        (__ \ 'lng).read[Double] and
          (__ \ 'lat).read[Double]
      )((lng, lat) => Location.apply(lng, lat)).reads(json)
  }
}
