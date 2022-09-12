package com.portl.commons.services

import org.slf4j.LoggerFactory
import play.api.libs.json._
import play.api.{Configuration, Environment}
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.api.{DefaultDB, indexes}
import reactivemongo.api.commands.CommandError
import reactivemongo.api.bson._
import reactivemongo.play.json.compat._
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.{ExecutionContext, Future}
import scala.io.Source
import com.portl.commons.models.schema.{Collection, Database, Schema}
import javax.inject.Inject

/**
  * Auto creates indexes on startup.
  * @author Kahli Burke
  */
class IndexCreatorService @Inject()(
    reactiveMongoApi: ReactiveMongoApi,
    environment: Environment,
    configuration: Configuration)(implicit executionContext: ExecutionContext) {

  val log = LoggerFactory.getLogger(getClass)

  val schemaUrl = environment.resource("schema.json")
  val source = Source.fromURL(schemaUrl.get)
  val content = source.getLines().mkString
  val schema = try {
    Json.parse(content).as[Schema]
  } finally {
    source.close()
  }

  private def getIndexType(typeValue: JsValue): indexes.IndexType = {
    //TODO: fixing this use of deprecated method
    import reactivemongo.play.json._
    indexes.IndexType(typeValue.as[reactivemongo.bson.BSONValue])
  }


  private def handleCollection(db: DefaultDB)(
      collDef: Collection): Future[Boolean] = {
    log.info(s"collection: ${collDef.name}")
    val collection = db.collection[JSONCollection](collDef.name)
    collection.create().recover {
      case CommandError.Code(48) =>
        log.info(s"collection exists: ${collDef.name}")
        () //name exists
    } flatMap { _ =>
      Future
        .sequence(
          collDef.indexes.map { indexDef =>
            // TODO : Handle more options. Currently we support only "unique" as an option in the schema file.
            val unique = indexDef.options
              .flatMap { opts =>
                (opts \ "unique").validate[Boolean].asOpt
              }
              .getOrElse(false)
            val name = indexDef.options.flatMap { opts =>
              (opts \ "name").validate[String].asOpt
            }
            val opts = indexDef.options.map { opts =>
              opts - "unique" - "name"
            }
            val bsonOpts: BSONDocument =
              opts.getOrElse(JsObject.empty).as[BSONDocument]
            val index = indexes.Index(
              key = indexDef.keys.fields.map { case (k, v) => (k, getIndexType(v)) },
              background = true,
              unique = unique,
              name = name,
              sparse = false,
              expireAfterSeconds = None,
              storageEngine = None,
              weights = None,
              defaultLanguage = None,
              languageOverride = None,
              textIndexVersion = None,
              sphereIndexVersion = None,
              bits = None,
              min = None,
              max = None,
              bucketSize = None,
              collation = None,
              wildcardProjection = None,
              version = None,
              partialFilter = None,
              options = bsonOpts
            )
            log.info(s"creating index $index")
            collection.indexesManager
              .create(index)
              .map(_.ok)
          }
        )
        .map(_.forall(identity))
    }
  }

  private def handleDb(dbDef: Database): Future[Boolean] = {
    val dbName = configuration.get[String](s"mongodb.dbs.${dbDef.name}")
    log.info(s"db: ${dbDef.name} -> $dbName")
    reactiveMongoApi.connection.database(dbName).flatMap { db =>
      Future
        .sequence(dbDef.collections.map(handleCollection(db)))
        .map(_.forall(identity))
    }
  }

  Future.sequence(schema.databases.map(handleDb)).map(_.forall(identity))
}
