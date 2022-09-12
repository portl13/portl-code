package com.portl.commons.models

import com.portl.commons.models.base.{MongoObjectId, StoredPortlEntity}
import com.portl.commons.serializers.MongoFormat
import com.portl.commons.serializers.Mongo._
import org.joda.time.DateTime
import play.api.libs.json.{Json, OFormat}

case class StoredArtist(
    id: MongoObjectId,
    externalId: SourceIdentifier,
    externalIdSet: Set[SourceIdentifier] = Set(),
    name: String,
    url: Option[String],
    imageUrl: String,
    description: Option[MarkupText],
    markedForDeletion: Option[DateTime]
) extends StoredPortlEntity

object StoredArtist {
  implicit val artistFormat: OFormat[StoredArtist] = MongoFormat(
    Json.format[StoredArtist])
}
