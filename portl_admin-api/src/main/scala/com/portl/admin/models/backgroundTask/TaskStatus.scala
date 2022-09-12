package com.portl.admin.models.backgroundTask

import enumeratum.{Enum, EnumEntry}
import play.api.libs.json.Reads.constraints
import play.api.libs.json._
import play.api.libs.functional.syntax._

sealed abstract class TaskStatus extends EnumEntry

object TaskStatus extends Enum[TaskStatus] {
  val values = findValues

  case object Scheduled extends TaskStatus
  case object InProgress extends TaskStatus
  case object Completed extends TaskStatus
  case object Failed extends TaskStatus

  implicit val eventCategoryFormat: Format[TaskStatus] = new Format[TaskStatus] {
    override def writes(ec: TaskStatus): JsValue = {
      JsString(ec.toString)
    }
    override def reads(json: JsValue): JsResult[TaskStatus] = {
      __.read[String](constraints.verifying[String](TaskStatus.withNameInsensitiveOption(_).isDefined)) andKeep
        __.read[String].map(TaskStatus.withNameInsensitive)
    }.reads(json)
  }
}
