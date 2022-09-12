package com.portl.admin.models.songkick

import play.api.libs.json._

case class Performance(
    artist: Option[Artist],
    displayName: String,
    billingIndex: Option[Int],
    id: Int,
    billing: Option[String]
)

object Performance {
  implicit val format: Format[Performance] = Json.format[Performance]
}
