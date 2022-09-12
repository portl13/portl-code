package com.portl.admin.models.ticketfly

import com.portl.admin.models.internal.InvalidEventException
import play.api.libs.json.{Json, OFormat}

case class VenueStub(
    id: Option[Int],
    name: Option[String],
    address1: Option[String],
    address2: Option[String],
    city: Option[String],
    stateProvince: Option[String],
    postalCode: Option[String], // "02116"
    country: Option[String], // "usa"
    lat: Option[String], // "42.349864"
    lng: Option[String], // "-71.065293"
    url: Option[String],
    timeZone: Option[String],
) {
  def asVenue: Venue =
    (lng, lat, id, timeZone) match {
      case (Some(lngVal), Some(latVal), Some(idVal), Some(tz)) =>
        Venue(
          idVal,
          name,
          address1,
          address2,
          city,
          stateProvince,
          postalCode,
          country,
          latVal,
          lngVal,
          url,
          tz
        )
      case _ => throw InvalidEventException("Events must have a lat/lng and tz")
    }
}

object VenueStub {
  implicit val format: OFormat[VenueStub] = Json.format[VenueStub]
}
