package com.portl.admin.models.internal.geocoding

import play.api.libs.json.{Json, OFormat}

case class ReverseGeocodingResult(
    formattedAddress: String,
    confidence: Int
)

object ReverseGeocodingResult {
  implicit val format: OFormat[ReverseGeocodingResult] = Json.format[ReverseGeocodingResult]
}
