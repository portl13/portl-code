package com.portl.api.services.queries
import play.api.libs.json.{JsNull, JsObject, Json, OWrites}

object Queries {

  case class ArtistByName(name: String)
  case class VenueByName(name: String)
  case class ByCaseInsensitiveSubstring(fieldName: String, substring: String)

  lazy val notMarkedForDeletion: JsObject = Json.obj("markedForDeletion" -> JsNull)

  implicit val artistByNameWrites: OWrites[ArtistByName] = (o: ArtistByName) =>
    // {$and: [{$text: {$search: "\"whole foods\""}}, {name: {$regex: "(?i)^foo fighters$"}}]}
    Json.obj(
      "$and" -> Json.arr(
        textIndexSearch(o.name),
        Json.obj("name" -> anchoredCaseInsensitiveRegexSearch(o.name)),
        notMarkedForDeletion))

  implicit val venueByNameWrites: OWrites[VenueByName] = (o: VenueByName) =>
    // {$text: {$search: "\"whole foods\""}}
    Json.obj("$and" -> Json.arr(textIndexSearch(o.name), notMarkedForDeletion))

  implicit val byCaseInsensitiveSubstringWrites: OWrites[ByCaseInsensitiveSubstring] =
    (o: ByCaseInsensitiveSubstring) => Json.obj(o.fieldName -> caseInsensitiveRegexSearch(o.substring))

  private def textIndexSearch(q: String): JsObject =
    Json.obj("$text" -> Json.obj("$search" -> s""""$q""""))

  private def anchoredCaseInsensitiveRegexSearch(q: String): JsObject =
    Json.obj("$regex" -> s"(?i)^$q$$")

  private def caseInsensitiveRegexSearch(q: String): JsObject =
    Json.obj("$regex" -> s"(?i)$q")
}
