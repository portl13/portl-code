package com.portl.admin.models.ticketmaster.v1

import com.portl.admin.models.internal
import com.portl.admin.models.internal.{Artist, InvalidEventException, MapsToPortlEntity}
import com.portl.commons.models._
import org.joda.time.DateTime
import play.api.libs.json.{Json, OFormat}

case class Event(
    eventName: String,
    eventId: String,
    primaryEventUrl: String,
    eventImageUrl: String,
    eventStartDateTime: Option[String],
    eventStartLocalDate: Option[String],
    eventEndTime: Option[String], // haven't seen this set in V1 test data yet, always null
    eventInfo: Option[String],
    venue: Venue,
    attractions: Option[List[AttractionWrapper]],
    // A Segment is a primary genre for an entity Music, Sports, Arts, etc)
    classificationSegment: Option[String],
    // Secondary Genre to further describe an entity (Rock, Classical, Animation, etc)
    classificationGenre: Option[String],
    // Tertiary Genre for additional detail when describing an entity (Alternative Rock,Ambient Pop, etc)
    classificationSubGenre: Option[String]
) extends MapsToPortlEntity[internal.Event] {

  def categories: Seq[EventCategory] =
    Seq(classificationSegment, classificationGenre, classificationSubGenre).flatten
      .map(EventCategory.getForCategoryString)

  def artist: Option[Artist] = attractions.flatMap(_.headOption.map(_.attraction.toPortl))

  override def toPortl: internal.Event = {
    (eventStartDateTime, eventStartLocalDate) match {
      case (Some(sdt), Some(lsd)) =>
        internal.Event(
          SourceIdentifier(EventSource.Ticketmaster, eventId),
          eventName,
          Some(eventImageUrl).find(_.nonEmpty).orElse(artist.map(_.imageUrl).find(_.nonEmpty)),
          eventInfo.map(i => MarkupText(i, MarkupType.PlainText)),
          DateTime.parse(sdt),
          eventEndTime.map(d => DateTime.parse(d)),
          venue.venueTimezone,
          categories,
          venue.toPortl,
          artist,
          Some(primaryEventUrl),
          Some(primaryEventUrl),
          lsd
        )
      case (Some(_), None) => throw InvalidEventException("Missing eventStartLocalDate")
      case _               => throw InvalidEventException("Missing eventStartDateTime")
    }
  }
}

object Event {
  implicit val eventFormat: OFormat[Event] = Json.format[Event]
}
