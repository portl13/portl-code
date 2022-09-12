package com.portl.api.models.controller

import com.portl.commons.models._
import org.joda.time.DateTime
import play.api.libs.json._
import com.portl.commons.serializers.Mongo._

case class EventP(
    id: String,
    title: String,
    imageUrl: Option[String],
    description: Option[MarkupText],
    startDateTime: DateTime,
    localStartDate: String,
    endDateTime: Option[DateTime],
    categories: Seq[EventCategory] = Seq(),
    venue: VenueP,
    artist: Option[ArtistP],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
    source: EventSource,
    computedDistance: Option[Double]
)

object EventP {
  implicit val eventPFormat = Json.format[EventP]

  def apply(event: StoredEvent): EventP =
    EventP(
      event.id.$oid,
      event.title,
      event.imageUrl,
      event.description,
      event.startDateTime,
      event.localStartDate,
      event.endDateTime,
      event.categories,
      VenueP(event.venue),
      event.artist.map(ArtistP(_)),
      event.url,
      event.ticketPurchaseUrl,
      event.externalId.sourceType,
      event.computedDistance
    )
}
