package com.portl.admin.models.internal

import com.portl.commons.models.{EventCategory, MarkupText, SourceIdentifier}
import com.portl.commons.serializers.Mongo._
import org.joda.time.DateTime
import play.api.libs.json._

case class Event(
    externalId: SourceIdentifier,
    title: String,
    imageUrl: Option[String],
    description: Option[MarkupText],
    startDateTime: DateTime,
    endDateTime: Option[DateTime],
    timezone: String,
    categories: Seq[EventCategory] = Seq(),
    venue: Venue,
    artist: Option[Artist],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
    localStartDate: String, // yyyy-mm-dd
    csvSource: Option[String] = None,
) extends StorablePortlEntity
    with MapsToPortlEntity[Event] {
  override def toPortl: Event = this
  override def toJsObject: JsObject = Json.toJsObject(this)
}

object Event {
  implicit val eventFormat: OFormat[Event] = Json.format[Event]

  val localDateFormat = "yyyy-MM-dd"
}
