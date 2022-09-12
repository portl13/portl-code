package com.portl.admin.models.internal

import com.portl.commons.models.{Address, Location, SourceIdentifier}
import play.api.libs.json.{JsObject, Json, OFormat}

case class Venue(
    externalId: SourceIdentifier,
    name: Option[String],
    location: Location,
    address: Address,
    url: Option[String]
) extends StorablePortlEntity
    with MapsToPortlEntity[Venue] {
  override def toPortl: Venue = this
  override def toJsObject: JsObject = Json.toJsObject(this)
}

object Venue {
  implicit val venueFormat: OFormat[Venue] = Json.format[Venue]
}
