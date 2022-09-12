package com.portl.admin.services.integrations

import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.commons.services.MongoService
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.Future

trait MappableEventStorageService[E <: MapsToPortlEntity[internal.Event]]
    extends MongoService
    with MappableEventSource[E] {

  /**
    * Used for logging etc.
    */
  val collectionName: String

  implicit def collection: Future[JSONCollection] = collection(collectionName)
}

case class RequestFailedException(private val message: String = "", private val cause: Throwable = None.orNull)
    extends Exception(message, cause)
