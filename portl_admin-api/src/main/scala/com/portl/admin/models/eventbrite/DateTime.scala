package com.portl.admin.models.eventbrite

import play.api.libs.json.{Format, Json}

case class DateTime(
    timezone: String,
    local: String,
    utc: String
)

object DateTime {
  implicit val searchResultFormat: Format[DateTime] = Json.format[DateTime]
}
