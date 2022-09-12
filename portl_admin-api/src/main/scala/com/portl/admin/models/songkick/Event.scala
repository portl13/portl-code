package com.portl.admin.models.songkick

import play.api.libs.json._
import org.joda.time.{DateTime, DateTimeZone}
import com.portl.admin.models.internal
import com.portl.admin.models.internal.{InvalidEventException, MapsToPortlEntity}
import com.portl.commons
import com.portl.commons.models.EventCategory._
import com.portl.commons.models.{Address, EventCategory, EventSource, SourceIdentifier}
import org.joda.time.format.{DateTimeFormat, DateTimeFormatter}

case class Event(
    displayName: String,
    `type`: String,
    uri: String,
    venue: SourceVenue,
    location: Location,
    start: DateTimeInfo,
    performance: List[Performance],
    // todo: want to change this id to a string
    id: Int
) extends MapsToPortlEntity[internal.Event] {

  private val startDateFormatter: DateTimeFormatter =
    DateTimeFormat.forPattern("yyyy-MM-dd").withZone(DateTimeZone.forID("America/Los_Angeles"))

  override def toPortl: internal.Event = {
    internal.Event(
      SourceIdentifier(EventSource.Songkick, s"$id"),
      displayName,
      None, // TODO: logo url
      None, // TODO: description
      startDateTime,
      None, // TODO: end datetime
      "", // TODO: timezone
      Seq(this.eventCategory),
      this.portlVenue,
      this.artist,
      Some(uri),
      Some(uri),
      start.date
    )
  }

  def portlVenue: internal.Venue = {
    val storedId = venue.id.map(_.toString).getOrElse(s"[${location.lng},${location.lat}]")
    val name = if (venue.id.isDefined) venue.displayName else venue.metroArea.displayName
    val address =
      location.city.split(", ") match {
        case Array(city, state, country) =>
          Address(None, None, Some(city), Some(state), None, Some(country))
        case Array(city, country) =>
          Address(None, None, Some(city), None, None, Some(country))
        case _ =>
          throw InvalidEventException(s"location.city was not comma-separated city[, state], country: ${location.city}")
      }
    internal.Venue(
      SourceIdentifier(EventSource.Songkick, storedId),
      Some(name),
      commons.models.Location(location.lng, location.lat),
      address,
      venue.uri
    )
  }

  private def startDateTime: DateTime = {
    start.datetime match {
      case Some(dt) => DateTime.parse(dt)
      case _        =>
        // TODO : Remove this jank before going international!
        // something like 25% of songkick events have no start.datetime, but they all have start.date ("2018-05-23")
        // if datetime is missing, just plant the start time in the middle of the day, pacific time
        // this way it will always land on the correct day regardless of the (us) timezone
        // To improve this, we should probably be looking up the correct timezone based on venue coords.
        DateTime.parse(start.date, startDateFormatter).withHourOfDay(12)
    }
  }

  private def eventCategory: EventCategory = {
    `type` match {
      case "Concert"  => Music
      case "Festival" => Community
    }
  }

  private def artist: Option[internal.Artist] = {
    performance.flatMap(_.artist).headOption.map(_.toPortl)
  }
}

object Event {
  implicit val format: OFormat[Event] = Json.format[Event]
}
