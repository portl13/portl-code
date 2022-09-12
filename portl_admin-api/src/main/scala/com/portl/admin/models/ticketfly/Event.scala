package com.portl.admin.models.ticketfly

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.models._
import org.joda.time.{DateTime, DateTimeZone}
import org.joda.time.format.DateTimeFormat
import play.api.libs.json._

case class Event(
    id: Int,
    venue: VenueStub,
    name: String,
    image: Option[Images],
    startDate: String, // "2017-03-31 10:00:00"
    endDate: Option[String], // "2020-03-31 02:00:00"
    ticketPurchaseUrl: String,
    headliners: Option[List[Artist]],
    urlEventDetailsUrl: Option[String],
    additionalInfo: Option[String] // html, deposit / cancellation policy
//    externalTicketingUrls: Option[List[String]], // []
//    org: JsObject,
//    featured: Boolean,
//    published: Boolean,
//    purchaseSkin: JsObject,
//    orgPurchaseSkin: JsObject,
//    slug: String,
//    publishDate: String,
//    dateCreated: String,
//    lastUpdated: String,
//    doorsDate: String,
//    onSaleDate: String,
//    offSaleDate: String,
//    onSaleDates: List[JsObject], // {name, startDate, endDate}
//    topLineInfo: String,
//    promoterName: String,
//    sponsorName: String,
//    sponsorImage: String,
//    additionalTicketText: String,
//    ageLimitCode: String, // null
//    ageLimit: String,
//    showTypeCode: String, // null
//    showType: String,
//    eventStatusCode: String, // "BUY"
//    eventStatus: String, // "Buy"
//    eventStatusMessage: String,
//    ticketPrice: String, // "150"
//    multiEventCartable: Boolean,
//    facebookEventId: String,
//    facebookEventIdString: String,
//    supports: List[String],
) extends MapsToPortlEntity[internal.Event] {
  private def getCategory: Seq[EventCategory] = {
    // POR-194 If comedy, sports, or film is in title, use that. Else, music.
    Seq(name.toLowerCase match {
      case s if s.contains("comedy") => EventCategory.Comedy
      case s if s.contains("sports") => EventCategory.Sports
      case s if s.contains("film")   => EventCategory.Film
      case _                         => EventCategory.Music
    })
  }

  def artist: Option[Artist] = headliners.flatMap(_.headOption)

  override def toPortl: internal.Event = {
    val checkedVenue = venue.asVenue
    val startDateTime = DateTimeFormat
      .forPattern("yyyy-MM-dd' 'HH:mm:ss")
      .withZone(DateTimeZone.forID(checkedVenue.timezone))
      .parseDateTime(startDate)
    internal.Event(
      SourceIdentifier(EventSource.Ticketfly, id.toString),
      name,
      image.flatMap(_.toSingleString).orElse(artist.flatMap(_.imageURL)),
      additionalInfo match {
        case Some(d) if d.length > 0 => Some(MarkupText(d, MarkupType.HTML))
        case _                       => None
      },
      startDateTime.toDateTime(DateTimeZone.UTC),
      endDate.map(DateTime.parse(_, DateTimeFormat.forPattern("yyyy-MM-dd' 'HH:mm:ss"))),
      checkedVenue.timezone,
      getCategory,
      checkedVenue.toPortl,
      artist.map(_.toPortl),
      Some(urlEventDetailsUrl.getOrElse(ticketPurchaseUrl)),
      ticketPurchaseUrl.length match {
        case 0 => None
        case _ => Some(ticketPurchaseUrl)
      },
      startDateTime.toString(internal.Event.localDateFormat)
    )
  }
}

object Event {
  import play.api.libs.json._

  val reads: Reads[Event] = Json.reads[Event]
  val writes: OWrites[Event] = Json.writes[Event]

  def read: JsValue => JsResult[Event] = { js =>
    js.validate[JsObject] match {
      case obj: JsSuccess[JsObject] =>
        val images: Option[Images] = (js \ "image").validate[Images].asOpt
        val eventJson = obj.get + ("image" -> Json.toJson(images))
        eventJson.validate[Event](reads)
      case err: JsError => err
    }
  }

  def write: Event => JsObject = writes.writes

  implicit val format: OFormat[Event] = OFormat(read, write)

  val requiredFields = Seq(
    "id",
    "name",
    "image",
    "startDate",
    "endDate",
    "additionalInfo",
    "showTypeCode",
    "showType",
    "ticketPurchaseUrl",
    "ticketPrice",
    "facebookEventId",
    "headliners.id",
    "headliners.name",
    "headliners.startTime",
    "headliners.urlOfficialWebsite",
    "headliners.urlMySpace",
    "headliners.urlFacebook",
    "headliners.urlTwitter",
    "headliners.urlAudio",
    "headliners.urlPurchaseMusic",
    "headliners.image.original",
    "headliners.image.xlarge",
    "headliners.image.large",
    "headliners.image.medium",
    "headliners.image.small",
    "headliners.image.xlarge1",
    "headliners.image.large1",
    "headliners.image.medium1",
    "headliners.image.small1",
    "headliners.image.square",
    "headliners.image.squareSmall",
    "venue.id",
    "venue.name",
    "venue.address1",
    "venue.address2",
    "venue.city",
    "venue.stateProvince",
    "venue.postalCode",
    "venue.country",
    "venue.url",
    "venue.lat",
    "venue.lng",
    "venue.timeZone",
    "urlEventDetailsUrl"
  )
}

/*
Fields we use (*: not using this, but shouldn't we?)

id
name
image
startDate
endDate
additionalInfo
showTypeCode *
showType *
ticketPurchaseUrl
ticketPrice *
facebookEventId *(dedupe?)
headliners.id
headliners.name
headliners.startTime
headliners.urlOfficialWebsite
headliners.urlMySpace
headliners.urlFacebook
headliners.urlTwitter
headliners.urlAudio
headliners.urlPurchaseMusic
headliners.image.original
headliners.image.xlarge
headliners.image.large
headliners.image.medium
headliners.image.small
headliners.image.xlarge1
headliners.image.large1
headliners.image.medium1
headliners.image.small1
headliners.image.square
headliners.image.squareSmall
venue.id
venue.name
venue.address1
venue.address2
venue.city
venue.stateProvince
venue.postalCode
venue.country
venue.url
venue.lat
venue.lng
urlEventDetailsUrl
 */

/*
Available fields (*: included in "light" fieldGroup)

id *
dateCreated
featured
published
publishDate
name *
headlinersName *
supportsName *
image
startDate *
endDate *
doorsDate *
onSaleDate
offSaleDate
topLineInfo *
promoterName
sponsorName
sponsorImage
additionalInfo
ageLimitCode *
ageLimit *
showTypeCode
showType
eventStatusCode *
eventStatus *
eventStatusMessage *
ticketPurchaseUrl *
ticketPrice *
facebookEventId
isMobileFriendly
headliners.id
headliners.name
headliners.startTime
headliners.eventDescription
headliners.urlOfficialWebsite
headliners.urlMySpace
headliners.urlFacebook
headliners.urlTwitter
headliners.urlAudio
headliners.urlPurchaseMusic
headliners.embedAudio
headliners.embedVideo
headliners.image.original
headliners.image.xlarge
headliners.image.large
headliners.image.medium
headliners.image.small
headliners.image.xlarge1
headliners.image.large1
headliners.image.medium1
headliners.image.small1
headliners.image.square
headliners.image.squareSmall
supports.id
supports.name
supports.startTime
supports.eventDescription
supports.urlOfficialWebsite
supports.urlMySpace
supports.urlFacebook
supports.urlTwitter
supports.urlAudio
supports.urlPurchaseMusic
supports.embedAudio
supports.embedVideo
supports.image.original
supports.image.xlarge
supports.image.large
supports.image.medium
supports.image.small
supports.image.xlarge1
supports.image.large1
supports.image.medium1
supports.image.small1
supports.image.square
supports.image.squareSmall
venue.id *
venue.name *
venue.timeZone
venue.address1
venue.address2
venue.city
venue.stateProvince
venue.postalCode
venue.country
venue.url
venue.blurb
venue.urlFacebook
venue.urlTwitter
venue.lat
venue.lng
venue.image
urlEventDetailsUrl

 */
