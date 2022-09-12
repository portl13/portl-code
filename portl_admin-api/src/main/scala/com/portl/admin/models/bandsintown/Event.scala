package com.portl.admin.models.bandsintown
import com.portl.admin.models.internal
import com.portl.admin.models.internal.InvalidEventException
import com.portl.admin.services.TimezoneResolver
import com.portl.commons.models._
import com.portl.commons.serializers.Mongo._
import org.joda.time.{DateTime, DateTimeZone}
import org.joda.time.format.{DateTimeFormat, DateTimeFormatter}
import play.api.libs.json.{JsObject, Json, OFormat}

/*
  EventData:
    type: object
    required:
    - id
    - artist_id
    - url
    - on_sale_datetime
    - datetime
    - venue
    - offers
    - lineup
    properties:
      id:
        type: string
        format: integer
        example: '13722599'
      artist_id:
        type: string
        format: integer
        example: '438314'
      url:
        type: string
        format: url
        example: 'http://www.bandsintown.com/event/13722599?app_id=foo&artist=Skrillex&came_from=67'
      on_sale_datetime:
        type: string
        format: datetime
        example: '2017-03-01T18:00:00'
      datetime:
        type: string
        format: datetime
        example: '2017-03-19T11:00:00'
      description:
        type: string
        example: 'This is a description'
      venue:
        $ref: '#/definitions/VenueData'
      offers:
        type: array
        items:
          $ref: '#/definitions/OfferData'
      lineup:
        type: array
        items:
          type: string
 */
case class Event(
    id: String, // numeric
    artist_id: String, // numeric
    url: String,
//    on_sale_datetime: DateTime,
    datetime: String,
    description: Option[String],
    venue: Venue,
    offers: Seq[JsObject], // OfferData, see bandsintown API docs
    lineup: Seq[String] // artist names
) {
  private val datetimeParser: DateTimeFormatter =
    DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss")

  def getTimezone(implicit timezoneResolver: TimezoneResolver): DateTimeZone = {
    val location = venue.location
    timezoneResolver
      .getTimezone(location)
      .getOrElse(throw InvalidEventException(s"Failed to resolve timezone for $location"))
  }

  def getStartDateTime(timezone: DateTimeZone): DateTime =
    // generally called with the result of `getTimezone`
    datetimeParser.withZone(timezone).parseDateTime(datetime)

  def localStartDate: String = datetimeParser.parseLocalDate(datetime).toString(internal.Event.localDateFormat)

  def toPortl(artist: Artist, artistDescription: Option[ArtistDescription] = None)(
      implicit timezoneResolver: TimezoneResolver): internal.Event = {
    val timezone = getTimezone

    internal.Event(
      SourceIdentifier(EventSource.Bandsintown, id),
      artist.name,
      Some(artist.image_url.trim).filter(_.nonEmpty),
      description.find(_.nonEmpty).map(MarkupText(_, MarkupType.PlainText)),
      getStartDateTime(timezone),
      None,
      timezone.getID,
      Seq(EventCategory.Music),
      venue.toPortl,
      Some(artist.toPortl(artistDescription)),
      Some(url),
      None,
      localStartDate
    )
  }
}

object Event {
  implicit val format: OFormat[Event] = Json.format[Event]
}
