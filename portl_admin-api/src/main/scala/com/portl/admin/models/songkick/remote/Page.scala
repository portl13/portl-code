package com.portl.admin.models.songkick.remote

import play.api.libs.json._

case class Page(
    totalEntries: Int,
    perPage: Int,
    page: Int,
    results: Events
)

object Page {
  implicit val format: Format[Page] = Json.format[Page]
}
