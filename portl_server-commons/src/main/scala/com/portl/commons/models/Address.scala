package com.portl.commons.models

import play.api.libs.json.{Json, OFormat}

case class Address(
    street: Option[String],
    street2: Option[String],
    city: Option[String],
    state: Option[String],
    zipCode: Option[String],
    country: Option[String],
)

object Address {
  implicit val format: OFormat[Address] = Json.format[Address]
}
