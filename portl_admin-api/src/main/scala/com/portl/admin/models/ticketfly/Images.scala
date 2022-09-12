package com.portl.admin.models.ticketfly

import play.api.libs.json.{Format, Json}

case class Images(
    original: Image,
    xlarge: Image,
    large: Image,
    medium: Image,
    small: Image,
    xlarge1: Image,
    large1: Image,
    medium1: Image,
    small1: Image,
    square: Image,
    squareSmall: Image,
) {
  def toSingleString: Option[String] =
    Seq(
      original,
      xlarge,
      large,
      medium,
      small,
      xlarge1,
      large1,
      medium1,
      small1,
      square,
      squareSmall
    ).map(_.path).find(_.length > 0)
}

object Images {
  implicit val format: Format[Images] = Json.format[Images]
}
