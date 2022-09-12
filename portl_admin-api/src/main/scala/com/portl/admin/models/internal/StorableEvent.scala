package com.portl.admin.models.internal

import com.portl.commons.models._
import com.portl.commons.serializers.Mongo._
import org.joda.time.DateTime
import play.api.libs.json._

case class StorableEvent(
    externalId: SourceIdentifier,
    title: String,
    imageUrl: Option[String],
    description: Option[MarkupText],
    startDateTime: DateTime,
    endDateTime: Option[DateTime],
    timezone: String,
    categories: Seq[EventCategory] = Seq(),
    venue: StoredVenue,
    artist: Option[StoredArtist],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
    localStartDate: String, // yyyy-mm-dd
    csvSource: Option[String] = None,
) extends StorablePortlEntity {
  override def toJsObject: JsObject = Json.toJsObject(this)
}

object StorableEvent {
  implicit val eventFormat: OFormat[StorableEvent] = Json.format[StorableEvent]

  def apply(e: Event, venue: StoredVenue, artistOption: Option[StoredArtist]): StorableEvent =
    StorableEvent(
      e.externalId,
      e.title,
      e.imageUrl,
      e.description.orElse(artistOption.flatMap(_.description)),
      e.startDateTime,
      e.endDateTime,
      e.timezone,
      e.categories,
      venue,
      artistOption,
      e.url,
      e.ticketPurchaseUrl,
      e.localStartDate,
      e.csvSource
    )
}
