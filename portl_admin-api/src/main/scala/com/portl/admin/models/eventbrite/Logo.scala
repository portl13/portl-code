package com.portl.admin.models.eventbrite

import play.api.libs.json.{Format, Json}

case class Logo(
    crop_mask: Option[CropMask],
    original: ImageLocation,
    id: String,
    url: String,
    aspect_ratio: String,
    edge_color: Option[String],
    edge_color_set: Option[Boolean]
)

object Logo {
  implicit val searchResultFormat: Format[Logo] = Json.format[Logo]
}
