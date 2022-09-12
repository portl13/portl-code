package com.portl.api.controllers

import javax.inject.Inject
import com.portl.api.actions.ApiAction
import com.portl.commons.models.base.MongoObjectId
import com.portl.api.models.controller._
import com.portl.api.models.input.{IdQuery, NameQuery}
import com.portl.api.services.{ArtistService, EventService}
import com.portl.commons.services.PaginationParams
import org.slf4j.LoggerFactory
import play.api.libs.json.Json
import play.api.mvc.{AbstractController, ControllerComponents}

import scala.concurrent.{ExecutionContext, Future}

class ArtistsController @Inject()(apiAction: ApiAction,
                                  cc: ControllerComponents,
                                  artistService: ArtistService,
                                  eventService: EventService,
                                  implicit val ec: ExecutionContext,
                                  implicit val configuration: play.api.Configuration)
    extends AbstractController(cc) {
  val log = LoggerFactory.getLogger(getClass)

  // todo: define date window for "upcoming" and "recent" events per POR-41 if intended for search as well
  // todo: eventservice already takes optional date params for setting date window

  def search = apiAction(parse.json).async { request =>
    val query = request.body.as[NameQuery]

    for {
      totalCount <- artistService.search(query.name).map(_.length)
      artists <- artistService.search(query.name, Some(PaginationParams(query.page, query.pageSize)))
      namesAndEvents <- Future.traverse(artists) { a =>
        eventService.findByArtist(a).map(a.name -> _)
      }
    } yield {
      Ok(
        Json.toJson(
          ArtistsByKeywordResponse(
            query.name,
            artists.map(
              a =>
                ArtistWithEventsResponse(
                  ArtistP(a),
                  namesAndEvents.find(ae => ae._1.equals(a.name)).map(_._2).getOrElse(List()).map(EventP(_))
              )
            ),
            totalCount,
            query.page,
            query.pageSize
          )
        )
      )
    }
  }

  // todo: define date window for "upcoming" and "recent" events per POR-41
  // todo: eventservice already takes optional date params for setting date window

  def findById = apiAction(parse.json).async { request =>
    val query = request.body.as[IdQuery]

    if (query.identifier.length == 24) {
      for {
        artist <- artistService.findById(MongoObjectId(query.identifier))
        events <- artist.map(a => eventService.findByArtist(a)).getOrElse(Future.successful(List()))
      } yield {
        artist
          .map(
            a =>
              Ok(
                Json.toJson(
                  ArtistByIdResponse(a.id.$oid, ArtistP(a), events.map(EventP(_)))
                )))
          .getOrElse(NoContent)
      }
    } else {
      Future.successful(NoContent)
    }
  }
}
