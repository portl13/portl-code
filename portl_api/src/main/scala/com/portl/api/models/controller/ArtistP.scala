package com.portl.api.models.controller

import com.portl.commons.models.{EventSource, MarkupText, StoredArtist}
import play.api.libs.json.Json

case class ArtistP(
    id: String,
    name: String,
    url: Option[String],
    imageUrl: String,
    description: Option[MarkupText],
    source: EventSource
)

object ArtistP {
  implicit val artistPFormat = Json.format[ArtistP]

  def apply(artist: StoredArtist): ArtistP =
    ArtistP(
      artist.id.$oid,
      artist.name,
      artist.url,
      artist.imageUrl,
      artist.description,
      artist.externalId.sourceType
    )
}
