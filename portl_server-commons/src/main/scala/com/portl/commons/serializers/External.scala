package com.portl.commons.serializers

import com.portl.commons.models._
import org.joda.time.format.ISODateTimeFormat
import org.joda.time.{DateTime, DateTimeZone}
import play.api.libs.functional.syntax._
import play.api.libs.json.Reads._
import play.api.libs.json._

object External {

  implicit val eventSourceFormat: Format[EventSource] =
    new Format[EventSource] {
      override def writes(es: EventSource): JsValue = {
        JsNumber(EventSource.indexOf(es))
      }
      override def reads(json: JsValue): JsResult[EventSource] = {
        __.read[Int](constraints.verifying[Int](i =>
          0 <= i && i < EventSource.values.length)) andKeep
          __.read[Int].map(EventSource.values(_))
      }.reads(json)
    }

  implicit val portlIdentifierFormat: Format[SourceIdentifier] = {
    object PortlIdentifierNaming extends JsonNaming {
      override def apply(property: String): String = {
        property match {
          case "identifierOnSource" => "id_on_source"
          case "sourceType"         => "source_type"
        }
      }
    }
    implicit val portlIdentifierConfig = JsonConfiguration(
      PortlIdentifierNaming)
    Json.format[SourceIdentifier]
  }

  implicit val portlLocationFormat: Format[Location] = new Format[Location] {
    override def writes(loc: Location): JsObject =
      Json.obj("lat" -> loc.latitude, "lng" -> loc.longitude)
    override def reads(json: JsValue): JsResult[Location] =
      (
        (__ \ 'lng).read[Double] and
          (__ \ 'lat).read[Double]
      )(Location.apply _).reads(json)
  }

  implicit val dateTimeWrites: Writes[DateTime] = (d: DateTime) => {
    import squants.time.TimeConversions._
    JsNumber(d.getMillis.milliseconds.toSeconds.toLong)
  }
  implicit val dateTimeReads: Reads[DateTime] = {
    case JsNumber(d) =>
      import squants.time.TimeConversions._
      JsSuccess(
        new DateTime(d.toLong.seconds.toMilliseconds.toLong, DateTimeZone.UTC))
    case JsString(s) =>
      JsSuccess(
        DateTime.parse(s,
                       ISODateTimeFormat.dateTimeParser().withOffsetParsed()))
    case _ =>
      JsError(Seq(JsPath() -> Seq(JsonValidationError("error.expected.date"))))
  }
  implicit val dateTimeFormat: Format[DateTime] =
    Format(dateTimeReads, dateTimeWrites)
}
