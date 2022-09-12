package com.portl.api.controllers

import javax.inject.Inject
import com.portl.api.actions.ApiAction
import com.portl.commons.models.base.MongoObjectId
import com.portl.api.models.controller._
import com.portl.api.models.input._
import play.api.libs.json._
import play.api.mvc.{AbstractController, Action, ControllerComponents}
import com.portl.api.services.{ArtistService, EventService}
import com.portl.commons.models.{EventCategory, Location, StoredEvent}
import com.portl.commons.services.PaginationParams
import org.slf4j.LoggerFactory
import squants.Length
import squants.space.LengthConversions._

import scala.concurrent.{ExecutionContext, Future}

class EventsController @Inject()(apiAction: ApiAction,
                                 cc: ControllerComponents,
                                 eventService: EventService,
                                 artistService: ArtistService,
                                 implicit val ec: ExecutionContext)
    extends AbstractController(cc) {
  val log = LoggerFactory.getLogger(getClass)

  def listAll = apiAction(parse.json).async { request =>
    // Longer max length on request body to support long id filter list.
    val query = request.body.as[AllQuery]

    val futureEvents = query.id match {
      case Some(ids) => eventService.findByIds(ids.map(MongoObjectId(_)))
      case _         => Future(List.empty)
    }

    futureEvents.map { events =>
      Ok(Json.toJson(EventsResponse(events.size, events.map(EventP(_)))))
    }
  }

  /**
    * Compute the distance between the given event and the target location.
    *
    * TODO : Remove this and do this computation client-side.
    *
    * @param e StoredEvent
    * @param l2 Location
    * @return The distance
    */
  private def distanceBetween(e: StoredEvent, l2: Location): Length = {
    val EARTH_RADIUS_KM = 6371

    val l1 = e.venue.location
    val latDistance = Math.toRadians(l1.latitude - l2.latitude)
    val lngDistance = Math.toRadians(l1.longitude - l2.longitude)
    val sinLat = Math.sin(latDistance / 2)
    val sinLng = Math.sin(lngDistance / 2)
    val a = sinLat * sinLat +
      (Math.cos(Math.toRadians(l1.latitude))
        * Math.cos(Math.toRadians(l2.latitude))
        * sinLng * sinLng)
    val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    (EARTH_RADIUS_KM * c).toInt.kilometers
  }

  def search: Action[JsValue] = apiAction(parse.json).async { request =>
    val querySpec = request.body.as[EventQuerySpec]

    val dist: Option[Length] = querySpec.maxDistanceMiles match {
      case Some(d) => Some(d.miles)
      case None    => None
    }
    val location = Location(querySpec.location.longitude, querySpec.location.latitude)
    val pagination = PaginationParams(querySpec.page, querySpec.pageSize)

    for {
      allIds <- eventService.findPaginatedIdsNear(
        location,
        pagination,
        dist,
        querySpec.startingAfter,
        querySpec.startingWithinDays,
        querySpec.categories
      )
      totalCount = allIds.count
      q = eventService.queryByObjectIds(allIds.ids)
      events <- eventService.findListSorted(q, eventService.sortByLocalStartDate)
    } yield {
      Ok(
        Json.toJson(
          EventSearchResponse(
            querySpec.location.latitude,
            querySpec.location.longitude,
            querySpec.maxDistanceMiles,
            querySpec.startingAfter,
            querySpec.startingWithinDays,
            querySpec.categories,
            events.map(e => EventSearchItem(e, Some(distanceBetween(e, location).toUsMiles))),
            totalCount,
            querySpec.page,
            querySpec.pageSize
          )
        )
      )
    }
  }

  def findById = apiAction(parse.json).async { request =>
    // TODO : throw 400 if query does not validate as IdQuery; add identifier string length validation.
    val query = request.body.as[IdQuery]

    if (query.identifier.length == 24) {
      for {
        event <- eventService.findById(MongoObjectId(query.identifier))
      } yield {
        event
          .map(e => Ok(Json.toJson(EventP(e))))
          .getOrElse(NoContent)
      }
    } else {
      Future.successful(NoContent)
    }
  }

  def getDefaultNewUserCategories = apiAction.async {
    eventService.findAllCategories.map(categories => Ok(Json.toJson(categories.map(CategoryP.fromCategory))))
  }

  def allCategories = apiAction.async { _ =>
    eventService.findAllCategories.map(categories => Ok(Json.toJson(categories.map(CategoryP.fromCategory))))
  }
}
