package com.portl.admin.models.portlAdmin
import java.util.UUID

import play.api.libs.json.{Json, OFormat}

case class SeededArtist(
    id: Option[UUID],
    name: String,
) extends HasID[SeededArtist] {
  override def withId(id: UUID): SeededArtist = copy(id = Some(id))
}

object SeededArtist {
  implicit val format: OFormat[SeededArtist] = Json.format[SeededArtist]
}
