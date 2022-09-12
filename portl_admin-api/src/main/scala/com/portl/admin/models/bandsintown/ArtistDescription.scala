package com.portl.admin.models.bandsintown
import play.api.libs.json.{Json, OFormat}

case class ArtistDescription(
    artistId: String,
    text: String
)

object ArtistDescription {
  implicit val format: OFormat[ArtistDescription] = Json.format[ArtistDescription]
}
