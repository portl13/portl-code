package com.portl.admin.controllers

import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.PORTLAdminController
import com.portl.admin.models.portlAdmin.bulk.ImportException
import com.portl.admin.models.{meetup, songkick}
import com.portl.admin.services.integrations._
import com.portl.commons.models.Location
import javax.inject.Inject
import play.api.libs.json.Json
import play.api.mvc._

import scala.concurrent.{ExecutionContext, Future}

// This class will probably go away and become a background service
class IntegrationsController @Inject()(cc: ControllerComponents,
                                       loggingActionBuilder: LoggingActionBuilder,
                                       bandsintownService: BandsintownService,
                                       eventbriteService: EventbriteService,
                                       meetupService: MeetupService,
                                       songkickService: SongkickService,
                                       ticketmasterService: TicketmasterService,
                                       ticketflyService: TicketflyService,
                                       implicit val ec: ExecutionContext)
    extends PORTLAdminController(cc, loggingActionBuilder) {

  def importBandsintownDescriptions = Action.async(parse.multipartFormData) { request =>
    val FILE_KEY = "artistDescriptions"

    request.body
      .file(FILE_KEY)
      .map { f =>
        bandsintownService
          .importDescriptions(f.ref)
          .map(r => Ok(Json.toJson(r)))
          .recover {
            case ImportException(msg, _) => BadRequest(msg)
          }
      }
      .getOrElse {
        Future(BadRequest(s"""Missing file "$FILE_KEY""""))
      }
  }

  // -- PROXY METHODS
  def getMeetup(lat: Double, lng: Double, offset: Int, raw: Boolean) = Action.async {
    log.info(s"get Meetup data request received: {lat:$lat, lng:$lng, offset:$offset, raw:$raw}")
    val params = meetup.remote.SearchParams(Location(lng, lat), offset)
    if (raw) {
      meetupService.getRawData(params).map { result =>
        Ok(Json.toJson(result))
      }
    } else {
      meetupService.getData(params).map { result =>
        Ok(Json.toJson(result))
      }
    }
  }

  def getEventbrite(lat: String, lng: String, radius: String, raw: Boolean) = Action.async {
    log.info(s"get Eventbrite data request received: {lat:$lat, lng:$lng, radius:$radius, raw:$raw}")

    if (raw)
      eventbriteService.getRawData(lat, lng, radius).map { result =>
        Ok(Json.toJson(result))
      } else
      eventbriteService.getData(lat, lng, radius).map { result =>
        Ok(Json.toJson(result))
      }
  }

  def getSongkick(lat: Double, lng: Double, page: Int, raw: Boolean) = Action.async {
    log.info(s"get Songkick data request received: {lat:$lat, lng:$lng, raw:$raw}")

    val params = songkick.remote.SearchParams(Location(lng, lat), page)

    if (raw)
      songkickService.getRawData(params).map { result =>
        Ok(Json.toJson(result))
      } else
      songkickService.getData(params).map { result =>
        Ok(Json.toJson(result))
      }
  }

  def getTicketmaster(lat: String, lng: String, raw: Boolean) = Action.async {
    log.info(s"get Ticketmaster data request received: {lat:$lat, lng:$lng, raw:$raw}")
    val params = Map("lat" -> lat, "lng" -> lng)
    if (raw)
      ticketmasterService.getRawData(params, 0).map { result =>
        Ok(Json.toJson(result))
      } else
      ticketmasterService.getData(params, 0).map { result =>
        Ok(Json.toJson(result))
      }
  }

  def getTicketfly(orgId: Int, pageNum: Int, raw: Boolean) = Action.async {
    log.info(s"get Ticketfly data request received: {orgId:$orgId, pageNum:$pageNum, raw:$raw}")
    val params = Map("orgId" -> orgId.toString)
    if (raw)
      ticketflyService.getRawData(params, pageNum).map { result =>
        Ok(Json.toJson(result))
      } else {
      for {
        result <- ticketflyService.getData(params, pageNum)
        _ <- ticketflyService.bulkUpsert(result.events)
      } yield Ok(Json.toJson(result))
    }
  }
}
