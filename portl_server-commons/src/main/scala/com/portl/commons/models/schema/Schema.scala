package com.portl.commons.models.schema

import play.api.libs.json.{Format, Json}

case class Schema(
    databases: Seq[Database]
)

object Schema {
  implicit val format: Format[Schema] = Json.format[Schema]
}
