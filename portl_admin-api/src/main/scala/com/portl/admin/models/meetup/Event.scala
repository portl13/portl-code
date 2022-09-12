package com.portl.admin.models.meetup

import com.portl.admin.models.internal
import com.portl.admin.models.internal.{InvalidEventException, MapsToPortlEntity}
import com.portl.commons.models.EventCategory.Community
import com.portl.commons.models.{EventSource, MarkupText, MarkupType, SourceIdentifier}
import com.portl.commons.serializers.Mongo.CustomLongReads
import org.joda.time.{DateTime, DateTimeZone}
import play.api.libs.json.{Json, OFormat}

case class Event(
    id: String,
    name: String,
    time: Long,
    utc_offset: Int, // millis
    venue: Option[Venue],
    event_url: String,
    photo_url: Option[String],
    description: Option[String],
    group: Group,
    // These are in the source data, but we don't use them:
//    duration: Option[Int],
//    how_to_find_us: Option[String],
//    created: Long,
//    updated: Long,
//    waitlist_count: Int,
//    yes_rsvp_count: Int,
//    status: String,
//    visibility: String
) extends MapsToPortlEntity[internal.Event] {

  override def toPortl: internal.Event = {
    venue match {
      case Some(venueVal) => {

        val photoUrl: Option[String] = photo_url match {
          case Some(photo_url) => Option(photo_url)
          case None => {
            group.group_photo match {
              case Some(group_photo) => group_photo.photo_link
              case None => None
            }
          }
        }

        val timeZone = DateTimeZone.forOffsetMillis(utc_offset)
        val startDateTime = new DateTime(time, timeZone)
        internal.Event(
          SourceIdentifier(EventSource.Meetup, id),
          name,
          photoUrl,
          description.map(MarkupText(_, MarkupType.HTML)),
          startDateTime,
          None,
          timeZone.getID,
          Seq(group.portlCategory),
          venueVal.toPortl,
          None,
          Some(event_url),
          None,
          startDateTime.toString(internal.Event.localDateFormat)
        )
      }
      case _ => throw InvalidEventException("no venue")
    }
  }
}

object Event {
  implicit val eventFormat: OFormat[Event] = Json.format[Event]
}
