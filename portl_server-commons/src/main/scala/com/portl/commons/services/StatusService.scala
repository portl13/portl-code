package com.portl.commons.services

import java.util.Date

import com.portl.commons.models.base.{MongoObject, MongoObjectId}
import play.api.libs.json.{Json, OFormat}
import play.modules.reactivemongo.ReactiveMongoApi
import com.portl.commons.serializers.Mongo._
import reactivemongo.api.{DefaultDB, indexes}
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.{ExecutionContext, Future}
import scala.io.Source
import com.portl.commons.models.schema._
import javax.inject.Inject
import play.api.Environment

class StatusService @Inject()(implicit val executionContext: ExecutionContext,
                              val reactiveMongoApi: ReactiveMongoApi,
                              val environment: Environment)
    extends SingleCollectionService[MongoStatusObject] {

  val objectId: MongoObjectId = MongoObjectId("5aac53057300003902296d1c")

  override val collectionName: String = "mongoStatus"

  def readWriteTest: Future[MongoStatusResult] = {
    val date = new Date().getTime

    for {
      writeStatusObjectResult <- upsert(MongoStatusObject(objectId, date))
      readStatusObject <- findById(objectId)
    } yield {
      MongoStatusResult(
        readStatusObject.isDefined,
        writeStatusObjectResult.ok,
        date
      )
    }
  }

  def checkIndexes: Future[Boolean] = {
    val schemaUrl = environment.resource("schema.json")
    val source = Source.fromURL(schemaUrl.get)
    val content = source.getLines().mkString
    val schema = try {
      Json.parse(content).as[Schema]
    } finally {
      source.close()
    }

    def indexPredicate(indexDef: Index)(index: indexes.Index): Boolean = {
      // TODO : Check index type and options
      val expectedKeys = indexDef.keys.keys
      val actualKeys = index.key.map(_._1).toSet
      expectedKeys == actualKeys
    }

    def testCollection(db: DefaultDB)(collDef: Collection): Future[Boolean] = {
      val collection = db.collection[JSONCollection](collDef.name)
      collection.indexesManager.list().map { indexes =>
        val result = collDef.indexes.forall { indexDef =>
          indexes.exists(indexPredicate(indexDef))
        }
        val resultString =
          if (result) "OK"
          else
            s"FAILED ==> expected: ${collDef.indexes} actual: ${indexes.toString}"
        log.debug(s"checkIndexes (${db.name}.${collDef.name}) $resultString")
        result
      }
    }

    def testDb(dbDef: Database): Future[Boolean] = {
      reactiveMongoApi.connection.database(dbDef.name).flatMap { db =>
        Future
          .sequence(dbDef.collections.map(testCollection(db)))
          .map(_.forall(identity))
      }
    }

    Future.sequence(schema.databases.map(testDb)).map(_.forall(identity))
  }
}

case class MongoStatusObject(id: MongoObjectId, date: Long) extends MongoObject

object MongoStatusObject {
  implicit val mongoStatusObjectFormat: OFormat[MongoStatusObject] =
    Json.format[MongoStatusObject]
}

case class MongoStatusResult(read: Boolean, write: Boolean, date: Long)

object MongoStatusResult {
  implicit val mongoStatusResultFormat = Json.format[MongoStatusResult]
}
