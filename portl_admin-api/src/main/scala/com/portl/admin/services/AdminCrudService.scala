package com.portl.admin.services

import java.util.UUID

import com.portl.admin.models.portlAdmin.HasID
import com.portl.commons.services.{MongoService, PaginationParams}
import play.api.libs.json._
import reactivemongo.api.ReadConcern
import reactivemongo.play.json.compat._
import reactivemongo.play.json.collection._

import scala.concurrent.Future

case class ByID(id: UUID)
object ByID {
  implicit val writes: OWrites[ByID] = (byID: ByID) => Json.obj("id" -> byID.id)
}

final case class PersistenceException(private val message: String = "", private val cause: Throwable = None.orNull)
    extends Exception(message, cause)

final case class NotFoundException(private val message: String = "", private val cause: Throwable = None.orNull)
    extends Exception(message, cause)

trait AdminCrudService[T <: HasID[T]] extends MongoService {
  val collectionName: String

  implicit def collection: Future[JSONCollection] = collection(collectionName)
  implicit val format: OFormat[T]

  val emptyQueryFormat: JsObject = Json.obj()

  def newId: UUID = UUID.randomUUID()

  def findById(id: UUID): Future[Option[T]] =
    withCollection { c =>
      c.findOne[ByID, T](ByID(id))
    }

  def getById(id: UUID): Future[T] = findById(id).map(_.getOrElse(throw NotFoundException(id.toString)))

  def create(entity: T): Future[T] = {
    val id = newId
    val withId = entity.withId(id)
    for {
      c <- collection
      writeResult <- c.insert(ordered = false).one(withId)
    } yield
      if (writeResult.ok) withId
      else
        throw PersistenceException(s"Failed to create $collectionName with id $id: ${writeResult.writeErrors}")
  }

  def update(entity: T): Future[T] = {
    val id = entity.id.getOrElse(throw PersistenceException(s"Attempt to update $collectionName with no id"))
    for {
      c <- collection
      result <- c.update(ordered = false).one(ByID(id), entity)
    } yield
      if (result.ok) entity
      else
        throw PersistenceException(s"Failed to update $collectionName with id $id: ${result.writeErrors}")
  }

  def delete(id: UUID): Future[Unit] = {
    for {
      c <- collection
      result <- c.delete().one(ByID(id))
    } yield
      if (result.ok) ()
      else
        throw PersistenceException(s"Failed to delete $id from $collectionName: ${result.writeErrors}")
  }

  def find[S](selector: Option[S] = None, pagination: Option[PaginationParams] = None, sortBy: Option[JsObject] = None)(
      implicit conv: S => JsObject): Future[List[T]] = {
    val s: JsObject = selector.map(conv).getOrElse(emptyQueryFormat)
    withCollection {
      pagination match {
        case Some(p) =>
          _.findListSortedPaginated[JsObject, T](s, sortBy.getOrElse(emptyQueryFormat), p.page, p.pageSize)
        case _ => _.findListSorted[JsObject, T](emptyQueryFormat, sortBy.getOrElse(emptyQueryFormat))
      }
    }
  }

  def findByName[S](name: String): Future[Option[T]] = {
    withCollection {
      _.findOne[JsObject, T](Json.obj("name" -> name))
    }
  }

  def count(selector: Option[JsObject] = None): Future[Long] = {
    withCollection {
      _.count(selector, None, 0, None, ReadConcern.Local)
    }
  }

}
