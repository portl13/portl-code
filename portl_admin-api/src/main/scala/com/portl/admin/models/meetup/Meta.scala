package com.portl.admin.models.meetup

import play.api.libs.json.{Json, OFormat}

case class Meta (
                next: String,
                method: String,
                total_count: Int,
                link: String,
                count: Int,
                )

object Meta {
  implicit val format: OFormat[Meta] = Json.format[Meta]
}