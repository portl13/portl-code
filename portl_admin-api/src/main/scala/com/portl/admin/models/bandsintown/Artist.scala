package com.portl.admin.models.bandsintown
import com.portl.admin.models.internal
import com.portl.commons.models.{EventSource, MarkupText, MarkupType, SourceIdentifier}
import play.api.libs.json.{Json, OFormat}

/*
  ArtistData:
    type: object
    required:
    - name
    - url
    - image_url
    - thumb_url
    - facebook_page_url
    - mbid
    - tracker_count
    - upcoming_event_count
    properties:
      id:
        type: integer
        example: 510
      name:
        type: string
        example: 'Maroon 5'
      url:
        type: string
        format: url
        example: 'http://www.bandsintown.com/Maroon5?came_from=67'
      image_url:
        type: string
        format: url
        example: 'https://s3.amazonaws.com/bit-photos/large/7481529.jpeg'
      thumb_url:
        type: string
        format: url
        example: 'https://s3.amazonaws.com/bit-photos/thumb/7481529.jpeg'
      facebook_page_url:
        type: string
        format: url
        example: 'https://www.facebook.com/maroon5'
      mbid:
        type: string
        example: '0ab49580-c84f-44d4-875f-d83760ea2cfe'
      tracker_count:
        type: integer
      upcoming_event_count:
        type: integer

 */
case class Artist(
    id: String, // supposed to be numeric, though
    name: String,
    url: String,
    image_url: String,
) {
  def toPortl(descriptionOption: Option[ArtistDescription]): internal.Artist = internal.Artist(
    SourceIdentifier(EventSource.Bandsintown, id),
    name,
    Some(url),
    image_url,
    descriptionOption.map { description =>
      MarkupText(description.text, MarkupType.PlainText)
    }
  )
}

object Artist {
  implicit val format: OFormat[Artist] = Json.format[Artist]
}
