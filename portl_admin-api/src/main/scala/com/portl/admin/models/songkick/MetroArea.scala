package com.portl.admin.models.songkick

import play.api.libs.json.{Json, OFormat}

case class MetroArea(
    displayName: String,
//    country: NamedObject,
//    state: Option[NamedObject],
//  uri: String,
//  id: Int,
)

object MetroArea {
  implicit val format: OFormat[MetroArea] = Json.format[MetroArea]
}
