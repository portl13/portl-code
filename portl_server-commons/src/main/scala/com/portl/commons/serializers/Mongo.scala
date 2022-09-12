package com.portl.commons.serializers

import play.api.libs.json._
import org.joda.time.{DateTime, DateTimeZone}

object Mongo {

  implicit val dateTimeWrites: Writes[DateTime] = (d: DateTime) => {
    JsNumber(d.getMillis)
  }

  implicit val dateTimeReads: Reads[DateTime] = {
    case JsNumber(d) => JsSuccess(new DateTime(d.toLong, DateTimeZone.UTC))
    case JsObject(d) => d("$long").validate[Long] match {
      case JsSuccess(value, _) => JsSuccess(new DateTime(value, DateTimeZone.UTC))
      case JsError(e) => JsError(e)
    }
    case e =>
      JsError(Seq(JsPath() -> Seq(JsonValidationError(s"error.expected.date, got $e"))))
  }

  implicit val dateTimeFormat: Format[DateTime] =
    Format(dateTimeReads, dateTimeWrites)

  implicit val CustomLongReads: Reads[Long] = {
    case JsNumber(d) => JsSuccess(d.longValue)
    case JsObject(d) => d("$long").validate[Long] match {
      case JsSuccess(value, _) => JsSuccess(value)
      case JsError(e) => JsError(e)
    }
    case e =>
      JsError(Seq(JsPath() -> Seq(JsonValidationError(s"error.expected.date, got $e"))))
  }
}
