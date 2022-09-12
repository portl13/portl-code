package com.portl.api.models.input

import play.api.libs.json.Json

case class NameQuery(name: String, page: Int, pageSize: Int)

object NameQuery {
  implicit val nameQueryFormat = Json.format[NameQuery]
}