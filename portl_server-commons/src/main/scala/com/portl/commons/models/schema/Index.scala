package com.portl.commons.models.schema

import play.api.libs.json.{Format, JsObject, Json}

/*
{
  "keys": {
    "externalId.sourceType": 1,
    "externalId.identifierOnSource": 1
  },
  "options": {
    "unique": true
  }
},
 */
case class Index(
    keys: JsObject,
    options: Option[JsObject]
)

object Index {
  implicit val format: Format[Index] = Json.format[Index]
}
