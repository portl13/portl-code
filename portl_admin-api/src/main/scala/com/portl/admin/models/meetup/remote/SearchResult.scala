package com.portl.admin.models.meetup.remote

import com.portl.admin.models.meetup.Meta
import play.api.libs.json.{JsObject, Json, OFormat}

case class SearchResult (
                        meta: Meta,
                        results: List[JsObject]
                        )

object SearchResult {
  implicit val format: OFormat[SearchResult] = Json.format[SearchResult]
}