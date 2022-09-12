package com.portl.admin.models.eventbrite

import com.portl.commons.models.{MarkupText, MarkupType}
import play.api.libs.json.{Format, Json}
import scala.language.implicitConversions

case class RichText(text: Option[String], html: Option[String])

object RichText {
  implicit val searchResultFormat: Format[RichText] = Json.format[RichText]

  implicit def toString(rt: RichText): String = {
    rt match {
      case RichText(Some(t), _) => t
      case _                    => ""
    }
  }

  implicit def toOptionMarkupText(rt: RichText): Option[MarkupText] = {
    rt match {
      case RichText(_, Some(h))    => Some(MarkupText(h, MarkupType.HTML))
      case RichText(Some(t), None) => Some(MarkupText(t, MarkupType.PlainText))
      case _                       => None
    }
  }
}
