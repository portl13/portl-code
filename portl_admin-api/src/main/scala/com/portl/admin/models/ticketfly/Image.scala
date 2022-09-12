package com.portl.admin.models.ticketfly

import play.api.libs.json.{Format, Json}

case class Image(
    path: String,
    width: Int,
    height: Int
)

object Image {
  implicit val format: Format[Image] = Json.format[Image]
}
