package com.portl.commons.services

import com.portl.commons.models.base.{MongoObject, MongoObjectId}
import com.portl.commons.models.{Location, SourceIdentifier}
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.api.{Cursor, QueryOpts, ReadConcern, ReadPreference}
import reactivemongo.api.commands.WriteResult
import reactivemongo.api.bson._
import reactivemongo.play.json.compat._
import reactivemongo.play.json.JSONSerializationPack.{Reader, Writer}
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.{ExecutionContext, Future}
import scala.language.higherKinds
import com.portl.commons.services.queries.CommonQueries.ByExternalId
import org.slf4j.LoggerFactory
import play.api.libs.json._
import reactivemongo.play.json.JSONSerializationPack
import reactivemongo.play.json.collection.JSONBatchCommands.AggregationFramework
import squants.Length

trait MongoService {
  val reactiveMongoApi: ReactiveMongoApi
  implicit val executionContext: ExecutionContext
  protected lazy val log = LoggerFactory.getLogger(getClass)

  def databaseName: Future[String] = reactiveMongoApi.database.map(_.name)

  def collection(name: String): Future[JSONCollection] =
    reactiveMongoApi.database.map(_(name))

  def withCollection[T](collection: Future[JSONCollection])(
      f: JSONCollection => Future[T]): Future[T] =
    collection flatMap f

  def withCollection[T](f: JSONCollection => Future[T])(
      implicit collection: Future[JSONCollection]): Future[T] = {
    withCollection(collection)(f)
  }

  def queryByObjectId(id: MongoObjectId): JsObject =
    Json.obj("_id" -> Json.toJson(id))

  def queryByObjectIds(ids: Iterable[MongoObjectId]): JsObject =
    Json.obj("_id" -> Json.obj("$in" -> ids))

  def sortByObjectId: JsObject = Json.obj("_id" -> 1)

  def byObjectId[T](collection: Future[JSONCollection], id: MongoObjectId)(
      implicit reads: Reads[T]
  ): Future[Option[T]] = {
    withCollection(collection) { c =>
      val query = queryByObjectId(id)
      c.findOne[JsObject, T](query)
    }
  }

  def byObjectId[T](id: MongoObjectId)(
      implicit collection: Future[JSONCollection],
      reads: Reads[T]
  ): Future[Option[T]] = {
    byObjectId[T](collection, id)
  }

  def dropCollection(collection: Future[JSONCollection]): Future[Boolean] =
    collection flatMap { c =>
      c.drop(failIfNotFound = false)
    }

  implicit class RichJsonCollection(val jsonCollection: JSONCollection) {
    val EARTH_RADIANS_TO_METERS = 0.000621371

    /**
      * The \$geoNear stage annotates documents with the distance (meters) from `location` in the `distanceField`. It
      * then sorts the collection by `distanceField` and selects documents while filtering by `query`.
      */
    def geoNear(
        location: Location,
        maxDistance: Option[Length],
        distanceField: Option[String] = None,
        query: Option[JsObject] = None
    ): AggregationFramework.GeoNear = {
      jsonCollection.BatchCommands.AggregationFramework.GeoNear(
        near = Json.obj(
          "type" -> "Point",
          "coordinates" -> Json.arr(location.longitude, location.latitude)
        ),
        spherical = true,
        maxDistance = maxDistance.map(_.toMeters.toLong),
        distanceMultiplier = Some(EARTH_RADIANS_TO_METERS),
        distanceField = distanceField.orElse(Some("__unused_distance")),
        query = query
      )
    }

    def findOne[S, T](selector: S)(
        implicit swriter: Writer[S],
        reader: Reader[T],
        executionContext: ExecutionContext
    ): Future[Option[T]] = {
      jsonCollection.find[S, JsObject](selector).one[T]
    }

    def findList[S, T](selector: S)(
        implicit swriter: Writer[S],
        reader: Reader[T],
        executionContext: ExecutionContext
    ): Future[List[T]] = {
      jsonCollection.find[S, JsObject](selector, None)
        .cursor[T](ReadPreference.primaryPreferred)
        .collect[List](-1, Cursor.ContOnError((_, ex: Throwable) => {
          log.warn(s"Failed to deserialize Mongo entity", ex)
        }))
    }

    def findListSorted[S, T](selector: S, sortBy: JsObject)(
        implicit swriter: Writer[S],
        reader: Reader[T],
        executionContext: ExecutionContext
    ): Future[List[T]] = {
      jsonCollection
        .find[S, JsObject](selector)
        .sort(sortBy)
        .cursor[T](ReadPreference.primaryPreferred)
        .collect[List](-1, Cursor.ContOnError((_, ex: Throwable) => {
          log.warn(s"Failed to deserialize Mongo entity", ex)
        }))
    }

    def findListSortedPaginated[S, T](selector: S,
                                      sortBy: JsObject,
                                      page: Int,
                                      itemsPerPage: Int)(
        implicit swriter: Writer[S],
        reader: Reader[T],
        executionContext: ExecutionContext
    ): Future[List[T]] = {
      jsonCollection
        .find[S, JsObject](selector)
        .sort(sortBy)
        .options(QueryOpts(skipN = page * itemsPerPage))
        .cursor[T](ReadPreference.primaryPreferred)
        .collect[List](itemsPerPage, Cursor.ContOnError((_, ex: Throwable) => {
          log.warn(s"Failed to deserialize Mongo entity", ex)
        }))
    }

    def countS[S](selector: S,
                  limit: Int = 0,
                  skip: Int = 0,
                  hint: Option[String] = None)(
        implicit swriter: Writer[S],
        executionContext: ExecutionContext): Future[Long] = {
      jsonCollection.count(Some(swriter.writes(selector)), Some(limit), skip, hint.map(jsonCollection.hint), ReadConcern.Available)
    }

  }

}

trait SingleCollectionService[T <: MongoObject] extends MongoService {
  val collectionName: String

  implicit def collection: Future[JSONCollection] = collection(collectionName)

  val emptyQueryFormat: JsObject = Json.obj()

  def all(pagination: Option[PaginationParams] = None,
          sortBy: Option[JsObject] = None)(
      implicit reads: Reads[T]): Future[List[T]] = {
    withCollection {
      pagination match {
        case Some(p) =>
          _.findListSortedPaginated[JsObject, T](
            emptyQueryFormat,
            sortBy.getOrElse(emptyQueryFormat),
            p.page,
            p.pageSize)
        case _ =>
          _.findListSorted[JsObject, T](emptyQueryFormat,
                                        sortBy.getOrElse(emptyQueryFormat))
      }
    }
  }

  def findById(id: MongoObjectId)(implicit reads: Reads[T]): Future[Option[T]] =
    byObjectId[T](id)

  def findByExternalId(id: SourceIdentifier)(
      implicit reads: Reads[T]): Future[Option[T]] = {
    withCollection {
      _.findOne[ByExternalId, T](
        ByExternalId(id)
      )
    }
  }

  def insert(t: T)(implicit writes: OWrites[T]): Future[WriteResult] = {
    withCollection { c =>
      c.insert(ordered = false).one(t)
    }
  }

  def update(t: T)(implicit writes: OWrites[T],
                   reads: Reads[T]): Future[WriteResult] = {
    withCollection { c =>
      c.update(ordered = false).one(queryByObjectId(t.id), t)(
        executionContext,
        JSONSerializationPack.IdentityWriter,
        writes
      )
    }
  }

  def upsert(t: T)(implicit writes: OWrites[T],
                   reads: Reads[T]): Future[WriteResult] = {
    withCollection { c =>
      c.update(ordered = false).one(queryByObjectId(t.id), t, upsert = true)(
        executionContext,
        JSONSerializationPack.IdentityWriter,
        writes
      )
    }
  }

  def dropCollection(): Future[Boolean] = dropCollection(collection)
}
