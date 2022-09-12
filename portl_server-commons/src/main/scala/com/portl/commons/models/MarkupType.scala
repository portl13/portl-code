package com.portl.commons.models

import enumeratum.{Enum, EnumEntry}
import play.api.libs.functional.syntax._
import play.api.libs.json.Reads._
import play.api.libs.json._

sealed abstract class MarkupType extends EnumEntry

object MarkupType extends Enum[MarkupType] {
  val values = findValues

  case object PlainText extends MarkupType
  case object HTML extends MarkupType

  implicit val markupTypeFormat: Format[MarkupType] = new Format[MarkupType] {
    override def writes(mt: MarkupType): JsValue = {
      JsString(mt.toString)
    }
    override def reads(json: JsValue): JsResult[MarkupType] = {
      __.read[String](
        constraints.verifying[String](
          MarkupType.withNameInsensitiveOption(_).isDefined)) andKeep
        __.read[String].map(MarkupType.withNameInsensitive)
    }.reads(json)
  }
}
