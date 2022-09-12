package com.portl.admin.models.internal.geocoding

import com.portl.commons.models.SourceIdentifier
import com.portl.commons.models.base.{MongoObject, MongoObjectId}
import play.api.libs.json.{Json, OFormat}

case class VenueGeocodingResult(
    id: MongoObjectId,
    externalId: SourceIdentifier,
    forwardGeocodingResult: Option[ForwardGeocodingResult],
    reverseGeocodingResult: Option[ReverseGeocodingResult]
) extends MongoObject

object VenueGeocodingResult {
  implicit val format: OFormat[VenueGeocodingResult] = Json.format[VenueGeocodingResult]
}
