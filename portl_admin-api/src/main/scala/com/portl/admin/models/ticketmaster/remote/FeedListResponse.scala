package com.portl.admin.models.ticketmaster.remote
import play.api.libs.json.{JsObject, Json, OFormat}

case class FeedListResponse(countries: JsObject)

object FeedListResponse {
  implicit val format: OFormat[FeedListResponse] = Json.format[FeedListResponse]
}
