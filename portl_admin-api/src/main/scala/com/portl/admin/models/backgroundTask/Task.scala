package com.portl.admin.models.backgroundTask

import com.portl.commons.models.base.{MongoObject, MongoObjectId}
import com.portl.commons.serializers.MongoFormat
import org.joda.time.DateTime
import play.api.libs.json._
import com.portl.commons.serializers.Mongo._

case class Task(
    id: MongoObjectId,
    status: TaskStatus,
    name: String,
    params: JsValue,
    created: DateTime,
    extra: JsValue,
) extends MongoObject

object Task {
  implicit val format: OFormat[Task] = MongoFormat(Json.format[Task])
}
