package com.portl.admin.models.portlAdmin

import java.util.UUID

import com.portl.admin.models.internal
import com.portl.admin.models.internal.{InvalidEventException, MapsToPortlEntity}
import com.portl.commons.models.{EventSource, MarkupText, MarkupType, SourceIdentifier}
import play.api.libs.json.OFormat
import play.api.libs.json._
import com.portl.commons.serializers.Mongo._

case class Artist(
    id: Option[UUID],
    name: String,
    url: Option[String],
    imageUrl: String,
    description: Option[String],
    officialUrl: Option[String],
    facebookUrl: Option[String],
    twitterUrl: Option[String],
    instagramUrl: Option[String],
    youtubeUrl: Option[String],
    spotifyUrl: Option[String],
    externalId: Option[String],
) extends HasID[Artist]
    with MapsToPortlEntity[internal.Artist] {
  override def toPortl: internal.Artist = {
    id.map { id =>
        internal.Artist(
          SourceIdentifier(EventSource.PortlServer, id.toString),
          name,
          url,
          imageUrl,
          description.map(MarkupText(_, MarkupType.PlainText)))
      }
      .getOrElse(throw InvalidEventException("missing id"))
  }

  override def withId(id: UUID): Artist = copy(id = Some(id))
}

object Artist {
  implicit val artistFormat: OFormat[Artist] = Json.format[Artist]
}
