package com.portl.admin.services

import java.util.UUID

import javax.inject.Inject

import scala.concurrent.{ExecutionContext, Future}
import play.modules.reactivemongo._
import com.portl.admin.models.portlAdmin.{Artist, Event}
import org.joda.time.{DateTime, DateTimeZone}
import org.joda.time.format.{DateTimeFormat, DateTimeFormatter}
import play.api.libs.json.JodaWrites.JodaDateTimeNumberWrites
import play.api.libs.json.{JodaWrites, JsObject, Json, OFormat, Writes}
import reactivemongo.api.ReadPreference
import reactivemongo.api.commands.UpdateWriteResult
import reactivemongo.play.json.compat._

class EventCrudService @Inject()(val reactiveMongoApi: ReactiveMongoApi,
                                 implicit val executionContext: ExecutionContext,
                                 artistCrudService: ArtistCrudService,
                                 venueCrudService: VenueCrudService,
                                 configuration: play.api.Configuration)
    extends AdminCrudService[Event] {
  val collectionName = "events"
  override implicit val format: OFormat[Event] = Event.eventFormat

  def byNameSelector(name: String): JsObject =
    Json.obj("$text" -> Json.obj("$search" -> s""""$name""""))

  def findExistingAdminEvent(eventName: String, eventStartTime: String, timezone: String, venueId: UUID, artistIdOpt: Option[UUID]): Future[Option[Event]] = {

    val formatter: DateTimeFormatter = DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss")
    val dateTimeTz: DateTime = formatter.withZone(DateTimeZone.forID(timezone)).parseDateTime(eventStartTime)

    implicit val epochWriter: Writes[DateTime] = JodaDateTimeNumberWrites
    val eventStartTimeEpoch = Json.toJson(dateTimeTz)(epochWriter)

    withCollection { collection =>
      val query = Json.obj(
        "title" -> eventName,
        "startDateTime" -> eventStartTimeEpoch,
        "venueId" -> venueId,
        "artistId" -> artistIdOpt,
      )

      collection.findOne[JsObject, Event](query)
    }
  }

  def bulkUpsert(events: Seq[Event]): Future[UpdateWriteResult] = {
    val IMPOSSIBLE_ID = -1
    val (withId, noPrimaryId) = events.partition(_.id.isDefined)
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
