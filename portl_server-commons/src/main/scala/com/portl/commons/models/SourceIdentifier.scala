package com.portl.commons.models

import play.api.libs.json.{Json, OFormat}

case class SourceIdentifier(
    sourceType: EventSource,
    identifierOnSource: String,
)

object SourceIdentifier {
  implicit val portlIdentifierFormat: OFormat[SourceIdentifier] =
    Json.format[SourceIdentifier]
}
