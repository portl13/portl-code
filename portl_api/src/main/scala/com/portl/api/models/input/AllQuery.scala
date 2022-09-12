package com.portl.api.models.input

import play.api.libs.json.Json

case class AllQuery(page: Int, pageSize: Int, id: Option[Iterable[String]])

object AllQuery {
  implicit val allQueryFormat = Json.format[AllQuery]
}
