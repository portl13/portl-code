package com.portl.api.models.input

import play.api.libs.json.Json

case class UpcomingQuery(page:Int, pageSize: Int, startDateTime: Option[String], durationDays: Option[Int])

object UpcomingQuery {
  implicit val upcomingQueryFormat = Json.format[UpcomingQuery]
}