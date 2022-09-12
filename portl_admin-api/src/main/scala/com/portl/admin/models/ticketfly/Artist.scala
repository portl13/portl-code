package com.portl.admin.models.ticketfly

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models.{EventSource, SourceIdentifier}
import play.api.libs.json._

case class Artist(
    id: Int,
    name: String,
    startTime: Option[String], // null
    image: Option[Images],
    urlAudio: Option[String],
    urlPurchaseMusic: Option[String],
    urlOfficialWebsite: Option[String],
    urlMySpace: Option[String],
    urlFacebook: Option[String],
    urlInstagram: Option[String],
    urlTwitter: Option[String],
    urlSoundcloud: Option[String],
    urlBandcamp: Option[String],
//    eventDescription: String,
//    isMobileFriendly: String, // "false"
//    youtubeVideos: List[String], // []
//    embedAudio: String,
//    embedVideo: String,
//    twitterScreenName: String,
) extends MapsToPortlEntity[internal.Artist] {
  def imageURL: Option[String] = image.flatMap(_.toSingleString)

  override def toPortl: internal.Artist = internal.Artist(
    SourceIdentifier(EventSource.Ticketfly, id.toString),
    name,
    Seq(
      urlOfficialWebsite,
      urlPurchaseMusic,
      urlFacebook,
      urlTwitter,
      urlInstagram,
      urlSoundcloud,
      urlBandcamp,
      urlAudio,
      urlMySpace).flatten.find(_.length > 0),
    imageURL.getOrElse(""),
    None
  )
}

object Artist {
  val reads: Reads[Artist] = Json.reads[Artist]
  val writes: OWrites[Artist] = Json.writes[Artist]

  def read: JsValue => JsResult[Artist] = { js =>
    js.validate[JsObject] match {
      case obj: JsSuccess[JsObject] =>
        val images: Option[Images] = (js \ "image").validate[Images].asOpt
        val eventJson = obj.get + ("image" -> Json.toJson(images))
        eventJson.validate[Artist](reads)
      case err: JsError => err
    }
  }

  def write: Artist => JsObject = writes.writes

  implicit val format: OFormat[Artist] = OFormat(read, write)
}
