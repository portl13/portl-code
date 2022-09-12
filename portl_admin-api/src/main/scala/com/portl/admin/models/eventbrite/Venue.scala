package com.portl.admin.models.eventbrite

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models.{EventSource, Location, SourceIdentifier}
import play.api.libs.json._

case class Venue(
    address: VenueAddress,
    resource_uri: String,
    id: String,
    name: Option[String],
    latitude: String,
    longitude: String
) extends MapsToPortlEntity[internal.Venue] {
  override def toPortl: internal.Venue = {
    internal.Venue(
      SourceIdentifier(EventSource.Eventbrite, id),
      name,
      Location(longitude.toDouble, latitude.toDouble),
      address.toPortl,
      Some(resource_uri)
    )
  }
}

object Venue {
  implicit val venueFormat: OFormat[Venue] = Json.format[Venue]
}
