package com.portl.api.models.controller

import com.portl.commons.models.EventCategory
import com.portl.commons.models.EventCategory.{Business, Yoga}
import play.api.libs.json.Json

case class CategoryP(name: String, display: String)

object CategoryP {
  implicit val categoryPFormat = Json.format[CategoryP]

  def fromCategory(eventCategory: EventCategory): CategoryP = eventCategory match {
    case Business         => CategoryP(Business.toString, "Workshops and Classes")
    case Yoga             => CategoryP(Yoga.toString, "Yoga & Wellness")
    case c: EventCategory => CategoryP(c.toString, c.toString)
  }
}
