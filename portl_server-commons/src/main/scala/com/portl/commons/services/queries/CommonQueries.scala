package com.portl.commons.services.queries

import com.portl.commons.models.SourceIdentifier
import play.api.libs.json.{Json, OFormat}

object CommonQueries {
  case class ByExternalId(externalId: SourceIdentifier)
  case class ByName(name: String)

  implicit val byNameFormat: OFormat[ByName] = Json.format[ByName]
  implicit val byExternalIdFormat: OFormat[ByExternalId] =
    Json.format[ByExternalId]
}
