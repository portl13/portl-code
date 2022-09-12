package com.portl.api.models.input

import play.api.libs.json.Json

case class IdQuery(identifier: String)

object IdQuery {
  implicit val IdQueryFormat = Json.format[IdQuery]
}
