package com.portl.admin.models.internal.geocoding

import enumeratum.{Enum, EnumEntry}
import play.api.libs.json._

sealed abstract class GeocodingResultStatus extends EnumEntry

object GeocodingResultStatus extends Enum[GeocodingResultStatus] {
  val values = findValues

  case object Success extends GeocodingResultStatus
  case object Error extends GeocodingResultStatus

  implicit val format: Format[GeocodingResultStatus] =
    new Format[GeocodingResultStatus] {
      override def writes(es: GeocodingResultStatus): JsValue = {
        JsString(es.entryName)
      }

      override def reads(json: JsValue): JsResult[GeocodingResultStatus] = {
        __.read[String].map(GeocodingResultStatus.namesToValuesMap(_))
      }.reads(json)
    }
}
