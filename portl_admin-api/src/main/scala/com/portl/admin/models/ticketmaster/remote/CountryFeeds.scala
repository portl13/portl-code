package com.portl.admin.models.ticketmaster.remote
import play.api.libs.json.{Json, OFormat}

case class CountryFeeds(
    XML: FeedDescription,
    CSV: FeedDescription,
    JSON: FeedDescription
)

object CountryFeeds {
  implicit val format: OFormat[CountryFeeds] = Json.format[CountryFeeds]
}
