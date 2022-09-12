package com.portl.admin.models.meetup

import com.portl.commons.models.EventCategory
import play.api.libs.json.{Json, OFormat}

case class GroupPhoto(
   highres_link: Option[String],
   photo_link: Option[String],
   thumb_link: Option[String])
object GroupPhoto {
  implicit val format: OFormat[GroupPhoto] = Json.format[GroupPhoto]
}

case class Group(
    id: Int,
    name: String,
    category: Option[Category],
    group_photo: Option[GroupPhoto]
//    join_mode: String,
//    created: Long,
//    urlname: String,
//    lat: Option[Double],
//    lon: Option[Double],
) {
  def portlCategory: EventCategory = category.map(_.portlCategory).getOrElse(EventCategory.Community)
}

object Group {
  implicit val format: OFormat[Group] = Json.format[Group]
}
