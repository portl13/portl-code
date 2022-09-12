package com.portl.admin.controllers

import akka.actor.ActorSystem
import akka.stream.Materializer
import akka.util.Timeout
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.PORTLAdminController
import com.portl.admin.models.internal
import com.portl.admin.models.internal.{MapsToPortlEntity, Venue}
import com.portl.admin.services.background.BackgroundTaskService
import com.portl.admin.services.integrations._
import javax.inject.Inject
import play.api.libs.json.Json
import play.api.mvc._
import reactivemongo.api.ReadConcern
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}
import scala.concurrent.duration._

class AdminController @Inject()(btService: BandsintownService,
                                ebService: EventbriteService,
                                muService: MeetupService,
                                skService: SongkickService,
                                tmService: TicketmasterService,
                                tfService: TicketflyService,
                                bgService: BackgroundTaskService,
                                portlService: PORTLService,
                                cc: ControllerComponents,
                                loggingActionBuilder: LoggingActionBuilder,
                                implicit val sys: ActorSystem,
                                implicit val materializer: Materializer,
                                implicit val ec: ExecutionContext)
    extends PORTLAdminController(cc, loggingActionBuilder) {

  implicit val timeout: Timeout = 5.seconds

  def pruneDuplicateVenues() = Action {
    portlService.pruneDuplicateVenues(None)
    Ok("started")
  }

  def pruneDuplicateVenuesByName(venueName: String, matchName: Boolean = true) = Action {
    portlService.pruneDuplicateVenues(Some(venueName), matchName)
    Ok("started")
  }

  def pruneDuplicateArtists() = Action {
    portlService.pruneDuplicateArtists()
    Ok("started")
  }

  def pruneDuplicateEvents() = Action {
    portlService.pruneDuplicateEvents(None)
    Ok("started")
  }

  def pruneDuplicateEventsByName(eventName: String) = Action {
    portlService.pruneDuplicateEvents(Some(eventName))
    Ok("started")
  }

  def deleteVenueIfNoEvents(venue: Venue) = {
    var logStr: String = ""
    for {
      eventsCount <- portlService.findByVenueCount(venue)
      _ <- {
        if (eventsCount == 0) {
          logStr += s"[pruneVenuesWithNoEvents] Marking venue for deletion: ${venue.name}"
          portlService.markVenueForDeletion(venue)
        }
        Future(None)
      }
    } yield {
      logStr += s"\n[pruneVenuesWithNoEvents] Venue ${venue.name} (${venue.externalId.identifierOnSource}) -- has ${eventsCount} events"
      log.info(logStr)
      venue
    }
  }

  def pruneVenuesWithNoEvents = Action {
    portlService.allVenuesSource(None)
      .mapAsync(1)(deleteVenueIfNoEvents)
      .runFold(0)((c, _) => {
        if (c % 10000 == 0) log.debug("pruneVenuesWithNoEvents {}", c+1)
        c + 1
      })
      .map { f =>
        log.info("pruneVenuesWithNoEvents done")
        f
      }
    Ok("Started")
  }

  def counts = Action.async {
    log.info("counts request received")
    for {
      artistCount <- portlService
        .collection(portlService.ARTISTS)
        .flatMap(_.count(None, None, 0, None, ReadConcern.Local))
      eventCount <- portlService
        .collection(portlService.EVENTS)
        .flatMap(_.count(None, None, 0, None, ReadConcern.Local))
      venueCount <- portlService
        .collection(portlService.VENUES)
        .flatMap(_.count(None, None, 0, None, ReadConcern.Local))

      btEventCount <- btService.countAllEvents
      ebEventCount <- ebService.countAllEvents
      muEventCount <- muService.countAllEvents
      skEventCount <- skService.countAllEvents
      tmEventCount <- tmService.countAllEvents
      tfEventCount <- tfService.countAllEvents

      bgCollection <- bgService.collection
      taskCount <- bgCollection.count(None, None, 0, None, ReadConcern.Local)
      tasksToday <- bgService.today
    } yield {
      Ok(
        Json.obj(
          "portl" -> Json.obj(
            "artistCount" -> artistCount,
            "eventCount" -> eventCount,
            "venueCount" -> venueCount
          ),
          "bandsintown" -> Json.obj(
            "eventCount" -> btEventCount
          ),
          "eventbrite" -> Json.obj(
            "eventCount" -> ebEventCount
          ),
          "meetup" -> Json.obj(
            "eventCount" -> muEventCount
          ),
          "songkick" -> Json.obj(
            "eventCount" -> skEventCount
          ),
          "ticketmaster" -> Json.obj(
            "eventCount" -> tmEventCount
          ),
          "ticketfly" -> Json.obj(
            "eventCount" -> tfEventCount
          ),
          "backgroundTasks" -> Json.obj(
            "totalCount" -> taskCount,
            "today" -> tasksToday
          )
        ))
    }
  }

  def storageServiceByName(serviceName: String): MappableEventStorageService[_ <: MapsToPortlEntity[internal.Event]] = {
    serviceName match {
      case "eb" => ebService
      case "mu" => muService
      case "sk" => skService
      case "tf" => tfService
      case "tm" => tmService
    }
  }
}
