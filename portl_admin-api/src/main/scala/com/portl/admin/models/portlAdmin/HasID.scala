package com.portl.admin.models.portlAdmin
import java.util.UUID

trait HasID[T] {
  val id: Option[UUID]
  def withId(id: UUID): T
}
