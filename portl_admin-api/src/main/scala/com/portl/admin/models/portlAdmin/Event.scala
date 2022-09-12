package com.portl.admin.models.portlAdmin

import java.util.UUID

import com.portl.admin.models.internal
import com.portl.admin.models.internal.InvalidEventException
import com.portl.commons.models._
import org.joda.time.{DateTime, DateTimeZone}
import play.api.libs.json.{JodaReads, JodaWrites, Json, OFormat, Reads, Writes}
import com.portl.commons.serializers.Mongo._

case class Event(
    id: Option[UUID],
    title: String,
    imageUrl: Option[String],
    description: Option[String],
    startDateTime: DateTime,
    endDateTime: Option[DateTime],
    timezone: String,
    categories: Set[EventCategory] = Set(),
    venueId: UUID,
    artistId: Option[UUID],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
    externalId: Option[String],
    csvSource: Option[String],
) extends HasID[Event] {
  def toPortl(venue: internal.Venue, artistOption: Option[internal.Artist]): internal.Event = {
    val localStartDateTime = startDateTime.withZone(DateTimeZone.forID(timezone))
    id.map { id =>
        internal.Event(
          SourceIdentifier(EventSource.PortlServer, id.toString),
          title,
          imageUrl.find(_.nonEmpty).orElse(artistOption.map(_.imageUrl).find(_.nonEmpty)),
          description.map(MarkupText(_, MarkupType.PlainText)),
          startDateTime,
          endDateTime,
          timezone,
          categories.toSeq,
          venue,
          artistOption,
          url,
          ticketPurchaseUrl,
          localStartDateTime.toString(internal.Event.localDateFormat),
          csvSource,
        )
      }
      .getOrElse(throw InvalidEventException("missing id"))
  }

  override def withId(id: UUID): Event = copy(id = Some(id))
}

object Event {
  implicit val eventFormat: OFormat[Event] = Json.format[Event]
}
