package com.portl.admin.models.eventbrite

import com.portl.commons.models.Address
import play.api.libs.json.{Format, Json}

case class VenueAddress(
    address_1: Option[String],
    address_2: Option[String],
    city: Option[String],
    region: Option[String],
    postal_code: Option[String],
    country: Option[String],
    //latitude: String,
    //longitude: String,
    localized_address_display: Option[String],
    //localized_area_display: Option[String],
    //localized_multi_line_address_display: Option[List[String]]
) {
  def displayString: Option[String] = {
    localized_address_display.orElse(
      List(address_1, address_2, city, region, postal_code, country).flatten.mkString(", ") match {
        case a if a.length > 0 => Some(a)
        case _                 => None
      }
    )
  }

  def toPortl: Address = Address(address_1, address_2, city, region, postal_code, country)
}

object VenueAddress {
  implicit val venueAddressFormat: Format[VenueAddress] = Json.format[VenueAddress]
}
