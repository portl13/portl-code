package com.portl.commons.models

import com.portl.commons.models.base.{MongoObjectId, StoredPortlEntity}
import com.portl.commons.serializers.MongoFormat
import com.portl.commons.serializers.Mongo._
import org.joda.time.DateTime
import play.api.libs.json.{Json, OFormat}

case class StoredEvent(
    id: MongoObjectId,
    externalId: SourceIdentifier,
    externalIdSet: Set[SourceIdentifier] = Set(),
    title: String,
    imageUrl: Option[String],
    description: Option[MarkupText],
    startDateTime: DateTime,
    endDateTime: Option[DateTime],
    categories: Seq[EventCategory] = Seq(),
    venue: StoredVenue,
    artist: Option[StoredArtist],
    url: Option[String],
    ticketPurchaseUrl: Option[String],
    computedDistance: Option[Double],
    localStartDate: String,
    markedForDeletion: Option[DateTime]
) extends StoredPortlEntity

object StoredEvent {
  implicit val format: OFormat[StoredEvent] = MongoFormat(
    Json.format[StoredEvent])
}
