package com.portl.commons.models

import enumeratum.{Enum, EnumEntry}
import play.api.libs.functional.syntax._
import play.api.libs.json.Reads.constraints
import play.api.libs.json._

sealed abstract class EventCategory(
    val matchPatterns: Set[String]
) extends EnumEntry {}

object EventCategory extends Enum[EventCategory] {
  val values = findValues

  case object Music
      extends EventCategory(
        Set("music", "music_event", "conference", "concert"))
  case object Family extends EventCategory(Set("family", "home"))
  case object Sports extends EventCategory(Set("sports", "fitness"))
  case object Business
      extends EventCategory(Set("business", "workshop", "work"))
  case object Theatre
      extends EventCategory(Set("theater", "theatre", "perform"))
  case object Comedy extends EventCategory(Set("comedy"))
  case object Food extends EventCategory(Set("food", "drink"))
  case object Film extends EventCategory(Set("film", "movie", "entertainment"))
  case object Yoga extends EventCategory(Set("yoga", "health"))
  case object Fashion extends EventCategory(Set("fashion", "beauty"))
  case object Community
      extends EventCategory(Set("other", "nightlife", "party", "festival"))
  case object Science
      extends EventCategory(Set("science", "technology", "technique"))
  case object Travel extends EventCategory(Set("travel", "outdoor"))
  case object Museum extends EventCategory(Set("museum"))

  case object Other extends EventCategory(Set())

  def getForCategoryString(categoryString: String): EventCategory = {
    val matchString = categoryString.toLowerCase
    EventCategory.values
      .find(c => c.matchPatterns.exists(s => matchString.contains(s)))
      .getOrElse(Other)
  }

  implicit val eventCategoryFormat: Format[EventCategory] =
    new Format[EventCategory] {
      override def writes(ec: EventCategory): JsValue = {
        JsString(ec.toString)
      }
      override def reads(json: JsValue): JsResult[EventCategory] = {
        __.read[String](
          constraints.verifying[String](
            EventCategory.withNameInsensitiveOption(_).isDefined)) andKeep
          __.read[String].map(EventCategory.withNameInsensitive)
      }.reads(json)
    }
}
