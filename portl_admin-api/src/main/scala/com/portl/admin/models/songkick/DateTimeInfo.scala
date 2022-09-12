package com.portl.admin.models.songkick

import org.joda.time.DateTime
import play.api.libs.json._
import com.portl.commons.serializers.External.dateTimeFormat

/*
{
"date": "2017-12-16"
}

{
"date": "2017-12-16",
"time": "20:00:00",
"datetime": "2017-12-16T20:00:00-0600"
}
 */

case class DateTimeInfo(
    date: String, // "2009-10-09"
    time: Option[String], // "19:00:00"
    datetime: Option[String] // "2010-02-17T19:30:00+0000"
)

object DateTimeInfo {

  implicit val format: Format[DateTimeInfo] = Json.format[DateTimeInfo]
}
