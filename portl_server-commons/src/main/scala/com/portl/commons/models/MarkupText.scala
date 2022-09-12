package com.portl.commons.models

import play.api.libs.json._

import scala.language.implicitConversions

case class MarkupText(
    value: String,
    markupType: MarkupType,
)

object MarkupText {
  implicit val markupTextFormat: Format[MarkupText] = Json.format[MarkupText]
}
