package com.portl.admin.models.portlAdmin.controller

import java.util.UUID

import com.portl.admin.models.portlAdmin.{Artist, Event, Venue}
import com.portl.commons.models.EventCategory
import com.portl.commons.serializers.Mongo._
import org.joda.time.DateTime
import play.api.libs.json.Json

case class EventWithDetailsResponse(
    id: Option[UUID],
    title: String,
    imageUrl: Option[String],
    description: Option[String],
    startDateTime: DateTime,
    endDateTime: Option[DateTime],
    timezone: String,
    categories: Set[EventCategory] = Set(),
    venue: Option[Venue],
    artist: Option[Artist],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
)

object EventWithDetailsResponse {
  def apply(e: Event, venueOpt: Option[Venue], artistOpt: Option[Artist]): EventWithDetailsResponse =
    EventWithDetailsResponse(
      e.id,
      e.title,
      e.imageUrl,
      e.description,
      e.startDateTime,
      e.endDateTime,
      e.timezone,
      e.categories,
      venueOpt,
      artistOpt,
      e.url,
      e.ticketPurchaseUrl
    )

  implicit val eventAFormat = Json.format[EventWithDetailsResponse]
}
