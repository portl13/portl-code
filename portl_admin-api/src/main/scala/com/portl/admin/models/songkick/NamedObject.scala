package com.portl.admin.models.songkick

import play.api.libs.json.{Json, OFormat}

case class NamedObject(
    displayName: String
)

object NamedObject {
  implicit val format: OFormat[NamedObject] = Json.format[NamedObject]
}
