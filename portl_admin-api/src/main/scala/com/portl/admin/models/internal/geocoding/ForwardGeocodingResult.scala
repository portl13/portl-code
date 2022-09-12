package com.portl.admin.models.internal.geocoding

import play.api.libs.json.{Json, OFormat}

case class ForwardGeocodingResult(
    latitude: Float,
    longitude: Float,
    radiusMiles: Option[Float],
    confidence: Int
)

object ForwardGeocodingResult {
  implicit val format: OFormat[ForwardGeocodingResult] = Json.format[ForwardGeocodingResult]
}
