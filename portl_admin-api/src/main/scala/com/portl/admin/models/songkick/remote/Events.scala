package com.portl.admin.models.songkick.remote

import play.api.libs.json.{Format, JsObject, Json}

case class Events(
    event: Option[List[JsObject]]
)

object Events {
  implicit val eventsFormat: Format[Events] = Json.format[Events]
}
