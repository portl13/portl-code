package com.portl.admin.models.ticketmaster.v1

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models.{EventSource, SourceIdentifier}
import play.api.libs.json.{Json, OFormat}

case class Attraction(
    attractionName: Option[String],
    attractionId: String,
    attractionUrl: Option[String],
    attractionImageUrl: Option[String],
) extends MapsToPortlEntity[internal.Artist] {
  override def toPortl: internal.Artist = {
    internal.Artist(
      SourceIdentifier(EventSource.Ticketmaster, attractionId),
      attractionName.getOrElse(""),
      attractionUrl,
      attractionImageUrl.getOrElse(""),
      None
    )
  }
}

object Attraction {
  implicit val attractionFormat: OFormat[Attraction] = Json.format[Attraction]
}
