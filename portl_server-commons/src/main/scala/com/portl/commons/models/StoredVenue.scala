package com.portl.commons.models

import com.portl.commons.models.base.{MongoObjectId, StoredPortlEntity}
import com.portl.commons.serializers.MongoFormat
import com.portl.commons.serializers.Mongo._
import org.joda.time.DateTime
import play.api.libs.json.{Json, OFormat}

case class StoredVenue(
    id: MongoObjectId,
    externalId: SourceIdentifier,
    externalIdSet: Set[SourceIdentifier] = Set(),
    name: Option[String],
    location: Location,
    address: Address,
    url: Option[String],
    markedForDeletion: Option[DateTime]
) extends StoredPortlEntity

object StoredVenue {
  implicit val format: OFormat[StoredVenue] = MongoFormat(
    Json.format[StoredVenue])
}
