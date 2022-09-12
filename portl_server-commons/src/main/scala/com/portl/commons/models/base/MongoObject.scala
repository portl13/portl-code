package com.portl.commons.models.base

import scala.language.implicitConversions
import play.api.libs.json.{Json, OWrites, Reads}
import reactivemongo.bson.BSONObjectID

case class MongoObjectId($oid: String) extends Ordered[MongoObjectId] {
  override def compare(that: MongoObjectId): Int = $oid.compare(that.$oid)
}

object MongoObjectId {
  def generate = MongoObjectId(BSONObjectID.generate().stringify)

  // Define back and forth implicit conversion
  implicit def mongoObjectId2BSONObjectId(oid: MongoObjectId): BSONObjectID =
    BSONObjectID.parse(oid.$oid).get
  implicit def bsonObjectId2MongoObjectId(oid: BSONObjectID): MongoObjectId =
    MongoObjectId(oid.stringify)

  // support {$oid: ...} wrapped ids, as provided by Mongo
  implicit val mongoObjectIdReads: Reads[MongoObjectId] =
    Json.reads[MongoObjectId]

  implicit val mongoObjectIdWrites: OWrites[MongoObjectId] =
    Json.writes[MongoObjectId]
}

trait MongoObject {
  val id: MongoObjectId
}
