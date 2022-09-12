package com.portl.commons.models.schema

import play.api.libs.json.{Format, Json}

/*
{
  "name": "portl",
  "collections": [ ... ]
}
 */
case class Database(
    name: String,
    collections: Seq[Collection]
)

object Database {
  implicit val format: Format[Database] = Json.format[Database]
}
