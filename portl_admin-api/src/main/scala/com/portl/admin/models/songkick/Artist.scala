package com.portl.admin.models.songkick

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models.{EventSource, SourceIdentifier}
import play.api.libs.json._

case class Identifier(
    mbid: String
)

case class Artist(
    uri: String,
    displayName: String,
    id: Int,
    // [{"mbid": "af37c51c-0790-4a29-b995-456f98a6b8c9"}]
    identifier: List[Identifier]
) extends MapsToPortlEntity[internal.Artist] {
  override def toPortl: internal.Artist = {
    internal.Artist(
      SourceIdentifier(EventSource.Songkick, id.toString),
      displayName,
      Some(uri),
      "",
      None
    )
  }
}

object Artist {
  implicit val idFormat: Format[Identifier] = Json.format[Identifier]
  implicit val format: OFormat[Artist] = Json.format[Artist]
}
