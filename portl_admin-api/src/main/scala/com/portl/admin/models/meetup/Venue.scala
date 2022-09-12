package com.portl.admin.models.meetup

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models.{Address, EventSource, Location, SourceIdentifier}
import org.apache.commons.codec.digest.DigestUtils
import play.api.libs.json.{Json, OFormat}

case class Venue(
    country: String,
//    localized_country_name: String,
    city: String,
    address_1: String,
    name: String,
    lat: Double,
    lon: Double,
    id: Option[Int],
    state: Option[String],
//    repinned: Boolean
) extends MapsToPortlEntity[internal.Venue] {
  def derivedId: String = DigestUtils.sha1Hex(s"$lon|$lat|$name")

  override def toPortl = {
    internal.Venue(
      SourceIdentifier(EventSource.Meetup, id.map(_.toString).getOrElse(derivedId)),
      Some(name),
      Location(lon, lat),
      Address(
        Some(address_1),
        None,
        Some(city),
        state,
        None,
        Some(country)
      ),
      None
    )
  }
}

object Venue {
  implicit val format: OFormat[Venue] = Json.format[Venue]
}
