package com.portl.admin.models.eventbrite

import play.api.libs.json.{Json, OFormat}

case class Category(
    resource_uri: String,
    id: String,
    name: String,
    name_localized: String,
    short_name: String,
    short_name_localized: String
)

object Category {
  implicit val inlineCategoryFormat: OFormat[Category] = Json.format[Category]
}
