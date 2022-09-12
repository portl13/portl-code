package com.portl.admin.models.internal

import play.api.libs.json.JsObject

/**
  * The PORTL representation of an entity received from an external source, ready for db storage.
  */
trait StorablePortlEntity extends PORTLEntity {
  def toJsObject: JsObject
}
