package com.portl.admin.models.bandsintown
import com.portl.admin.models.internal
import com.portl.admin.models.internal.{InvalidEventException, MapsToPortlEntity}
import com.portl.commons.models.{Address, EventSource, Location, SourceIdentifier}
import org.apache.commons.codec.digest.DigestUtils
import play.api.libs.json.{Json, OFormat}

/*
  VenueData:
    type: object
    required:
    - name
    - latitude
    - longitude
    - city
    - region
    - country
    properties:
      name:
        type: string
        example: 'Encore Beach Club'
      latitude:
        type: string
        format: double
        example: '36.12714'
      longitude:
        type: string
        format: double
        example: '-115.1629562'
      city:
        type: string
        example: 'Las Vegas'
      region:
        type: string
        example: 'NV'
      country:
        type: string
        example: 'United States'

 */
case class Venue(
    name: String,
    latitude: String,
    longitude: String,
    city: String,
    region: String,
    country: String,
) extends MapsToPortlEntity[internal.Venue] {
  def derivedId: String = DigestUtils.sha1Hex(s"$longitude|$latitude|$name")

  def location =
    try {
      Location(longitude.toDouble, latitude.toDouble)
    } catch {
      case _: NumberFormatException => throw InvalidEventException("malformed lat/lng")
    }

  override def toPortl: internal.Venue = {
    internal.Venue(
      SourceIdentifier(EventSource.Bandsintown, derivedId),
      Some(name),
      location,
      Address(
        None,
        None,
        Some(city.trim).filter(_.nonEmpty),
        Some(region.trim).filter(_.nonEmpty),
        None,
        Some(country.trim).filter(_.nonEmpty)),
      None
    )
  }
}

object Venue {
  implicit val format: OFormat[Venue] = Json.format[Venue]
}
