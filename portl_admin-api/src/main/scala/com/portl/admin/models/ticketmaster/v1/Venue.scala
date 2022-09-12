package com.portl.admin.models.ticketmaster.v1

import com.portl.admin.models.internal
import com.portl.admin.models.internal.{InvalidEventException, MapsToPortlEntity}
import com.portl.commons.models.{Address, EventSource, Location, SourceIdentifier}
import play.api.libs.json._

case class Venue(
    venueName: String,
    venueId: String,
    venueUrl: Option[String],
    venueLatitude: Option[Float],
    venueLongitude: Option[Float],
    venueStreet: Option[String],
    venueCity: Option[String],
    venueStateCode: Option[String],
    venueCountryCode: Option[String],
    venueZipCode: Option[String],
    venueTimezone: String,
) extends MapsToPortlEntity[internal.Venue] {

  override def toPortl: internal.Venue = {
    (venueLatitude, venueLongitude) match {
      case (Some(lat), Some(lng)) =>
        internal.Venue(
          SourceIdentifier(EventSource.Ticketmaster, venueId),
          Some(venueName),
          Location(lng.toDouble, lat.toDouble),
          Address(venueStreet, None, venueCity, venueStateCode, venueZipCode, venueCountryCode),
          venueUrl
        )
      case _ => throw InvalidEventException("Event venues must have a location")
    }
  }
}

object Venue {
  implicit val resultsFormat: OFormat[Venue] = Json.format[Venue]
}
