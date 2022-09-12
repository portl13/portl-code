package com.portl.commons.serializers

import play.api.libs.json._

case class MongoFormat[T](f: OFormat[T]) extends OFormat[T] {
  override def reads(json: JsValue): JsResult[T] = readsMongoId(f).reads(json)
  override def writes(o: T): JsObject = writesMongoId(f).writes(o)

  private def readsMongoId(r: Reads[T]) = {
    __.json.update((__ \ 'id).json.copyFrom((__ \ '_id).json.pick)) andThen r
  }

  private def writesMongoId(w: OWrites[T]) = {
    w transform { jsObj: JsObject =>
      jsObj \ "id" match {
        case JsDefined(oid) => jsObj - "id" ++ Json.obj("_id" -> oid)
        case JsUndefined()  => throw MongoObjectIdException(jsObj)
      }
    }
  }
}

case class MongoObjectIdException(jsv: JsValue)
    extends RuntimeException(s"No 'id' field found in object: $jsv")
