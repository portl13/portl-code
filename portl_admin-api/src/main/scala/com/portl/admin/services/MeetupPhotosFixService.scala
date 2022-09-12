package com.portl.admin.services

import akka.http.scaladsl.model.HttpHeader.ParsingResult.Ok
import akka.Done
import akka.stream.Materializer
import akka.stream.scaladsl.Source
import com.portl.admin.models.internal.{Event, Venue}
import com.portl.admin.models.meetup.{Event => MeetupEvent}
import com.portl.commons.models.{EventSource, SourceIdentifier}
import javax.inject.Inject
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import com.portl.commons.services.MongoService
import com.portl.commons.services.queries.CommonQueries.ByExternalId
import play.api.libs.json.{JsObject, Json, OFormat, OWrites}
import reactivemongo.akkastream.cursorProducer
import reactivemongo.api.{Cursor, ReadPreference}
import reactivemongo.api.commands.UpdateWriteResult
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

class MeetupPhotosFixService @Inject()(
          @NamedDatabase("data") val reactiveMongoApi: ReactiveMongoApi,
          @NamedDatabase("meetup") val reactiveMongoMeetup: ReactiveMongoApi,
          implicit val executionContext: ExecutionContext,
          implicit val materializer: Materializer) extends MongoService {

  def updateEventsWithNoPhotoAsync() = {
    getMeetupWithoutPhotosSource()
      .mapAsync(1)(addGroupPhoto)
      .runFold(0)((count, _) => {
        if (count % 10000 == 0) {
          log.info("[updateEventsWithNoPhotosAsync()] Adding Meetup photos @ {}", count)
        }
        count + 1
      })
      .map(number => {
        log.info("[updateEventsWithNoPhotosAsync()] Completed adding Meetup photos @ {}", number)
        number
      })
  }

  def getMeetupWithoutPhotosSource() = {
    val futureSource = for {
      c <- collection("events")
    } yield {
      c.find[MeetupNoPhotos, Event](MeetupNoPhotos(), None)
        .cursor[Event](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson[Event](event.get).toString, e)
        }))
    }

    Source.fromFutureSource(futureSource)
  }

  def addGroupPhoto(event: Event) = {
    for {
      photoEventOpt <- createPhotoWithMeetupQuery(event)
      done <- updateEvent(photoEventOpt)
    } yield done
  }

  def createPhotoWithMeetupQuery(event: Event): Future[Option[Event]] = {
    for {
      meetupEvent <- getSpecificMeetupEvent(event.externalId.identifierOnSource)
    } yield {
      meetupEvent match {
        case Some(meetupEvent) => {

          meetupEvent.group.group_photo match {
            case Some(group_photo) => {
              val groupPhoto = group_photo.photo_link
              Option(event.copy(imageUrl=groupPhoto))
            }
            case None => None
          }

        }
        case None => None
      }
    }
  }

  def getSpecificMeetupEvent(id: String): Future[Option[MeetupEvent]] = {
    implicit val format: OFormat[MeetupEvent] = Json.format[MeetupEvent]
    for {
      c <- reactiveMongoMeetup.database.map(_.collection[JSONCollection]("events"))
      meetupEvent <- {
        c.findOne[ByInternalId, MeetupEvent](ByInternalId(id))
          .recover({
            case err => {
              log.error("[updateEventsWithNoPhotosAsync()] Error decoding event {}", id)
              None
            }
          })
      }
    } yield meetupEvent
  }

  def updateEvent(photoEventOpt: Option[Event]): Future[Done] = {
    photoEventOpt match {
      case Some(photoEvent) => {
        for {
          c <- collection("events")
          writeResult <- {
            val eventId = photoEvent.externalId.identifierOnSource
            val eventTitle = photoEvent.title
            log.info(s"[updateEventsWithNoPhotosAsync()] Updating Meetup photo for $eventId ($eventTitle)")
            val selector = ByExternalId(SourceIdentifier(EventSource.Meetup, eventId))
            c.update(ordered = false).one(selector, photoEvent).recover({
              case err => err.printStackTrace()
            })
          }
        } yield Done
      }
      case None => Future(Done)
    }
  }
}

private case class MeetupNoPhotos()
private object MeetupNoPhotos {
  implicit val writes: OWrites[MeetupNoPhotos] = new OWrites[MeetupNoPhotos] {
    override def writes(o: MeetupNoPhotos): JsObject = Json.obj(
      "externalId.sourceType" -> Json.toJsFieldJsValueWrapper(7),
      "imageUrl" -> Json.obj("$exists" -> Json.toJsFieldJsValueWrapper(false))
    )
  }
}

private case class ByInternalId(id: String)
private object ByInternalId {
  implicit val writes: OWrites[ByInternalId] = (byId: ByInternalId) => {
    Json.obj(
      "id" -> byId.id
    )
  }
}

