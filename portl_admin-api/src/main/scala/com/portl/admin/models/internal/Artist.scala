package com.portl.admin.models.internal

import com.portl.commons.models.{MarkupText, SourceIdentifier}
import play.api.libs.json.OFormat
import play.api.libs.json._

case class Artist(
    externalId: SourceIdentifier,
    name: String,
    url: Option[String],
    imageUrl: String,
    description: Option[MarkupText]
) extends StorablePortlEntity
    with MapsToPortlEntity[Artist] {
  override def toPortl: Artist = this
  override def toJsObject: JsObject = Json.toJsObject(this)
}

object Artist {
  implicit val artistFormat: OFormat[Artist] = Json.format[Artist]
}
