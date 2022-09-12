package com.portl.commons.models

import play.api.libs.json.Reads.{constraints, minLength}
import play.api.libs.json._
import play.api.libs.functional.syntax._

case class Location(longitude: Double, latitude: Double)

object Location {
  private val portlLocationWrites =
    OWrites[Location](
      p =>
        Json.obj("type" -> "Point",
                 "coordinates" -> List(p.longitude, p.latitude)))

  private val portlLocationReads =
    (__ \ 'type)
      .read[String](constraints.verifying[String](_ == "Point")) andKeep
      (__ \ 'coordinates).read[Location](minLength[List[Double]](2).map(l =>
        Location(l(0), l(1))))

  implicit val portlLocationFormat: OFormat[Location] =
    OFormat(portlLocationReads, portlLocationWrites)

}
