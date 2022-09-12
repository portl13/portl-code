package com.portl.admin.models.ticketmaster.remote
import play.api.libs.json.{Json, OFormat}

case class FeedDescription(
    uri: String,
    country_code: String,
    format: String,
    compressed_md5_checksum: String,
    compressed_size_bytes: Int,
    last_updated: String,
    num_events: Int,
    //  "uri": "https://s3.amazonaws.com/dc-feeds-prod1-public/20180731/EVENTS_RAW-AT-56f4b0aa-c40c-46c5-a070-7d1e87127b1f-2018-07-31_100441.xml.gz",
    //  "country_code": "AT",
    //  "format": "XML",
    //  "compressed_md5_checksum": "9ff12e730058544c40bd73ca6d7b0440",
    //  "compressed_size_bytes": 248145,
    //  "last_updated": "2018-07-31T22:04:41Z",
    //  "num_events": 249
)

object FeedDescription {
  implicit val format: OFormat[FeedDescription] = Json.format[FeedDescription]
}
