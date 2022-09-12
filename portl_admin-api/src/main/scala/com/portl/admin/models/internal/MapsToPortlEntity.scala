package com.portl.admin.models.internal

/**
  * Marks entities coming from third party sources that are meant to map to a StorablePortlEntity.
  */
trait MapsToPortlEntity[A <: PORTLEntity] {
  def toPortl: A
}

final case class InvalidEventException(private val message: String = "", private val cause: Throwable = None.orNull)
    extends Exception(message, cause);
