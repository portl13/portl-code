package com.portl.api.controllers

import javax.inject.Inject
import com.portl.api.actions.ApiAction
import com.portl.commons.models.base.MongoObjectId
import com.portl.api.models.controller._
import com.portl.api.models.input.{IdQuery, NameWithLocationQuery}
import com.portl.api.services.{EventService, VenueService}
import com.portl.commons.models.Location
import com.portl.commons.services.PaginationParams
import play.api.libs.json.Json
import play.api.mvc.{AbstractController, ControllerComponents}
import squants.Length
import squants.space.LengthConversions._

import scala.concurrent.{ExecutionContext, Future}

class VenuesController @Inject()(apiAction: ApiAction,
                                 cc: ControllerComponents,
                                 venueService: VenueService,
                                 eventService: EventService,
                                 implicit val ec: ExecutionContext)
    extends AbstractController(cc) {

  def search = apiAction(parse.json).async { request =>
    // todo: limit returned events by time window tbd
    val query = request.body.as[NameWithLocationQuery]

    val dist: Option[Length] = query.maxDistanceMiles match {
      case Some(d) => Some(d.miles)
      case None    => None
    }

    val pagination = PaginationParams(query.page, query.pageSize)
    val futureResponse = query.location match {
      case Some(location) =>
        searchNear(query.name, Location(location.longitude, location.latitude), pagination, dist)
      case _ =>
        searchAll(query.name, pagination)
    }

    futureResponse.map(r => Ok(Json.toJson(r)))
  }

  def findById = apiAction(parse.json).async { request =>
    val query = request.body.as[IdQuery]

    if (query.identifier.length == 24) {
      for {
        venue <- venueService.findById(MongoObjectId(query.identifier))
        events <- venue.map(v => eventService.findByVenue(v)).getOrElse(Future.successful(List()))
      } yield {
        venue
          .map(
            v =>
              Ok(
                Json.toJson(
                  VenueWithEventsResponse(
                    v.id.$oid,
                    VenueP(v),
                    events.map(EventP(_))
                  )
                )))
          .getOrElse(NoContent)
      }
    } else {
      Future.successful(NoContent)
    }
  }

  private def searchNear(name: String,
                         location: Location,
                         pagination: PaginationParams,
                         dist: Option[Length]): Future[VenuesByKeywordResponse] = {
    for {
      idAggregationResult <- venueService.findPaginatedIdsNear(name, location, Some(pagination), dist)
      venues <- venueService.searchNear(name, location, Some(pagination))
      namesAndEvents <- Future.traverse(venues) { v =>
        eventService.findByVenue(v).map(v.name -> _)
      }
    } yield {
      val responseVenues = venues.map(
        v =>
          VenueWithEventsResponse(
            v.id.$oid,
            VenueP(v),
            namesAndEvents.find(ve => ve._1.equals(v.name)).map(_._2).getOrElse(List()).map(EventP(_))))
      VenuesByKeywordResponse(name, responseVenues, idAggregationResult.count, pagination.page, pagination.pageSize)
    }
  }

  private def searchAll(name: String, pagination: PaginationParams): Future[VenuesByKeywordResponse] = {
    for {
      totalCount <- venueService.search(name).map(_.length)
      venues <- venueService.search(name, Some(pagination))
      namesAndEvents <- Future.traverse(venues) { v =>
        eventService.findByVenue(v).map(v.name -> _)
      }
    } yield {
      val responseVenues = venues.map(
        v =>
          VenueWithEventsResponse(
            v.id.$oid,
            VenueP(v),
            namesAndEvents.find(ve => ve._1.equals(v.name)).map(_._2).getOrElse(List()).map(EventP(_))))
      VenuesByKeywordResponse(name, responseVenues, totalCount, pagination.page, pagination.pageSize)
    }
  }
}
