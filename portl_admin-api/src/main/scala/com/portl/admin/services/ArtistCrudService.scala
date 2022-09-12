package com.portl.admin.services

import java.util.UUID

import akka.stream.Materializer
import com.portl.admin.models.portlAdmin.Artist
import javax.inject.Inject
import play.api.libs.json.{JsObject, Json, OFormat}
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.api.ReadPreference
import reactivemongo.api.commands.UpdateWriteResult
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

class ArtistCrudService @Inject()(
    implicit val executionContext: ExecutionContext,
    implicit val materializer: Materializer,
    val reactiveMongoApi: ReactiveMongoApi
) extends AdminCrudService[Artist] {
  val collectionName = "artists"
  override implicit val format: OFormat[Artist] = Artist.artistFormat

  def byNameSelector(name: String): JsObject =
    Json.obj("$text" -> Json.obj("$search" -> s""""$name""""))

  def bulkUpsert(artists: Seq[Artist]): Future[UpdateWriteResult] = {
    val IMPOSSIBLE_ID = -1
    val (withId, noPrimaryId) = artists.partition(_.id.isDefined)
    val (withExternalId, noId) = noPrimaryId.partition(_.externalId.isDefined)
    log.debug(s"bulkUpsert {withId:${withId.length}, withExternalId:${withExternalId.length}, noId:${noId.length}}")

    withCollection { collection =>
      import collection.BatchCommands._
      import UpdateCommand._
      val updates = withId.map { a =>
        UpdateElement(
          q = Json.obj("id" -> a.id.get),
          u = a,
          upsert = true
        )
      } ++ withExternalId.map { a =>
        UpdateElement(
          q = Json.obj("externalId" -> a.externalId.get),
          u = a.copy(id=Some(UUID.randomUUID())),
          upsert = true
        )
      } ++ noId.map { a =>
        UpdateElement(
          q = Json.obj("id" -> IMPOSSIBLE_ID),
          u = a.copy(id=Some(UUID.randomUUID())),
          upsert = true
        )
      }
      val update = Update(updates.head, updates.tail: _*)
      collection.runCommand(update, ReadPreference.primary).map { r =>
        log.debug(s"$r")
        r
      }
    }
  }

}
