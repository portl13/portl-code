package com.portl.admin.models.meetup
import com.portl.commons.serializers.Mongo.CustomLongReads
import play.api.libs.json.{Json, OFormat}

case class LatestMTime(mtime: Long)

object LatestMTime {
  implicit val format: OFormat[LatestMTime] = Json.format[LatestMTime]
}
