package com.portl.admin.models.portlAdmin

import java.util.UUID

import com.portl.admin.models.internal
import com.portl.admin.models.internal.{InvalidEventException, MapsToPortlEntity}
import com.portl.commons.models.{Address, EventSource, Location, SourceIdentifier}
import play.api.libs.json.{Json, OFormat}
import com.portl.commons.serializers.Mongo._
import reactivemongo.bson.BSONObjectID

case class Venue(
                  id: Option[UUID],
                  name: String,
                  location: Location,
                  address: Address,
                  url: Option[String],
) extends HasID[Venue]
    with MapsToPortlEntity[internal.Venue] {
  override def toPortl: internal.Venue = {
    id.map { id =>
        internal.Venue(
          SourceIdentifier(EventSource.PortlServer, id.toString),
          Some(name),
          location,
          address,
          url
        )
      }
      .getOrElse(throw InvalidEventException("missing id"))
  }

  override def withId(id: UUID): Venue = copy(id = Some(id))
}

object Venue {
  implicit val venueFormat: OFormat[Venue] = Json.format[Venue]
}
