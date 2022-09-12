package com.portl.commons.models.schema

import play.api.libs.json.{Format, Json}

/*
{
  "name": "artists",
  "indexes": [ ... ]
}
 */
case class Collection(
    name: String,
    indexes: Seq[Index]
)

object Collection {
  implicit val format: Format[Collection] = Json.format[Collection]
}
