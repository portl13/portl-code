package com.portl.api.models.controller

import com.portl.commons.models.{Address, EventSource, StoredVenue}
import play.api.libs.json._

case class VenueP(
    id: String,
    name: Option[String],
    location: Location,
    address: Address,
    url: Option[String],
    source: EventSource
)

object VenueP {
  implicit val venuePFormat = Json.format[VenueP]

  def apply(venue: StoredVenue): VenueP =
    VenueP(
      venue.id.$oid,
      venue.name,
      Location(venue.location),
      venue.address,
      venue.url,
      venue.externalId.sourceType
    )
}
