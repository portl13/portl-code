package com.portl.admin.models.ticketfly

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models.{Address, EventSource, Location, SourceIdentifier}
import play.api.libs.json.{Json, OFormat}

case class Venue(
    id: Int,
    name: Option[String],
    address1: Option[String],
    address2: Option[String],
    city: Option[String],
    stateProvince: Option[String],
    postalCode: Option[String], // "02116"
    country: Option[String], // "usa"
    lat: String, // "42.349864"
    lng: String, // "-71.065293"
    url: Option[String],
//    metroCode: String, // "506"
    timezone: String,
//    blurb: String,
//    urlFacebook: String,
//    urlTwitter: String,
//    image: JsObject,
) extends MapsToPortlEntity[internal.Venue] {
  override def toPortl: internal.Venue = internal.Venue(
    SourceIdentifier(EventSource.Ticketfly, id.toString),
    name,
    Location(lng.toDouble, lat.toDouble),
    Address(address1, address2, city, stateProvince, postalCode, country),
    url
  )
}

object Venue {
  implicit val format: OFormat[Venue] = Json.format[Venue]
}
