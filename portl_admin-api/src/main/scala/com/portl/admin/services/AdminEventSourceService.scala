package com.portl.admin.services
import akka.stream.Materializer
import akka.stream.scaladsl.Source
import akka.stream.ActorAttributes.supervisionStrategy
import akka.stream.Supervision.resumingDecider
import com.portl.admin.models.{internal, portlAdmin}
import com.portl.admin.services.integrations.MappableEventStorageService
import com.portl.commons.futures.FutureHelpers
import com.portl.commons.models.EventSource
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.json._
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.akkastream.{State, cursorProducer}
import reactivemongo.api.{Cursor, ReadPreference}
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

/**
  * Special case of MappableEventStorageService.
  *
  * This produces internal.Event objects (effectively the target required for storage in PORTLService) instead of
  * portlAdmin.Event objects (the type stored in the portlAdmin data store). This is because portlAdmin.Event references
  * artist and venue by id instead of storing them embedded, so portlAdmin.Event.toPortl cannot be synchronous.
  *
  * TODO : abstract out the portlAdmin.Event -> internal.Event transformation required here so more of the
  * allEventsSource / upcomingEventsSource methods can be shared with the base class.
  */
class AdminEventSourceService @Inject()(venueCrudService: VenueCrudService,
                                        artistCrudService: ArtistCrudService,
                                        val reactiveMongoApi: ReactiveMongoApi,
                                        implicit val executionContext: ExecutionContext,
                                        implicit val materializer: Materializer)
    extends MappableEventStorageService[internal.Event] {

  val collectionName = "events"
  override def eventsSinceSelector(since: DateTime): JsObject =
    // "startDateTime" : NumberLong("1543086000000"), (millis)
    Json.obj("startDateTime" -> Json.obj("$gte" -> since.getMillis))

  override implicit val format: OFormat[internal.Event] = internal.Event.eventFormat
  override val eventSource: EventSource = EventSource.PortlServer

  private def portlEventsSource(selector: JsObject): Future[Source[portlAdmin.Event, Future[State]]] = {
    for {
      c <- collection
    } yield {
      c.find(selector, Some(projection))
        .cursor[JsObject](ReadPreference.secondaryPreferred)
        .documentSource(err = Cursor.ContOnError((event, e) => {
          log.error(Json.toJson(event).toString, e)
        }))
        .map[JsResult[portlAdmin.Event]](_.validate[portlAdmin.Event])
        .filter({
          case JsSuccess(_, _) => true
          case JsError(errors) =>
            log.debug(errors.mkString(" "))
            false
        })
        .collect { case JsSuccess(e, _) => e }
    }
  }

  private def transform(adminEvent: portlAdmin.Event): Future[internal.Event] = {
    for {
      venue <- {
        venueCrudService.getById(adminEvent.venueId)
      }
      artistOption <- FutureHelpers.traverseOption(adminEvent.artistId)(artistCrudService.getById)
    } yield {
      val internalVenue = venue.toPortl
      val internalArtist = artistOption.map(_.toPortl)
      adminEvent.toPortl(internalVenue, internalArtist)
    }
  }

  override def allEventsSource: Future[Source[internal.Event, Future[State]]] = {
    for {
      s <- portlEventsSource(JsObject.empty)
    } yield s.mapAsync(1)(transform)
  }

  override def upcomingEventsSource: Future[Source[internal.Event, Future[State]]] = {
    for {
      documentSource <- portlEventsSource(eventsSinceSelector(upcomingEventsStartDate))
    } yield {
      documentSource
        .mapAsync(1)(transform)
        .withAttributes(supervisionStrategy(resumingDecider)
      )
    }
  }

}
