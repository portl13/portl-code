package com.portl.admin.models.meetup
import com.portl.commons.models.EventCategory
import play.api.libs.json.{Json, OFormat}

case class Category(
    name: String,
    id: Int,
    shortname: String,
) {
  def portlCategory: EventCategory = Category.eventCategoryMapping.getOrElse(shortname, EventCategory.Community)
}

object Category {
  implicit val format: OFormat[Category] = Json.format[Category]

  // Mapping from shortname to corresponding PORTL category.
  val eventCategoryMapping: Map[String, EventCategory] = Map(
    "photography" -> EventCategory.Film,
    "tech" -> EventCategory.Science,
    "outdoors-adventure" -> EventCategory.Travel,
    "sports-recreation" -> EventCategory.Sports,
    "food-drink" -> EventCategory.Food,
    "music" -> EventCategory.Music,
    "fitness" -> EventCategory.Sports,
    "career-business" -> EventCategory.Business,
    "movies-film" -> EventCategory.Film,
    "fashion-beauty" -> EventCategory.Fashion,
    "parents-family" -> EventCategory.Family,
    // To map:
    "community-environment" -> EventCategory.Community,
    "religion-beliefs" -> EventCategory.Community,
    "health-wellbeing" -> EventCategory.Community,
    "new-age-spirituality" -> EventCategory.Community,
    "arts-culture" -> EventCategory.Community,
    "socializing" -> EventCategory.Community,
    "book-clubs" -> EventCategory.Community,
    "language" -> EventCategory.Community,
    "sci-fi-fantasy" -> EventCategory.Community,
    "education-learning" -> EventCategory.Community,
    "cars-motorcycles" -> EventCategory.Community,
    "hobbies-crafts" -> EventCategory.Community,
    "writing" -> EventCategory.Community,
    "dancing" -> EventCategory.Community,
    "games" -> EventCategory.Community,
    "support" -> EventCategory.Community,
    "government-politics" -> EventCategory.Community,
    "lgbt" -> EventCategory.Community,
    "singles" -> EventCategory.Community,
    "pets-animals" -> EventCategory.Community,
    "paranormal" -> EventCategory.Community,
    "lifestyle" -> EventCategory.Community,
  )
}
