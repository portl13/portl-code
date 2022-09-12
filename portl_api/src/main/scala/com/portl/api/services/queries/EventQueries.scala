package com.portl.api.services.queries

import com.portl.commons.models.{StoredArtist, StoredVenue}
import com.portl.commons.serializers.Mongo._
import org.joda.time.DateTime
import play.api.libs.json.{JsObject, Json, OWrites}

object EventQueries {
  case class EventsByStartTime(startTime: DateTime, before: DateTime)
  case class EventsByArtist(artist: StoredArtist, byStartTime: Option[EventsByStartTime] = None)
  case class EventsByVenue(venue: StoredVenue, byStartTime: Option[EventsByStartTime] = None)

  implicit val eventByStartTimeFormat = new OWrites[EventsByStartTime] {
    override def writes(eventByStartTime: EventsByStartTime): JsObject =
      Json.obj(
        "startDateTime" -> Json.obj(
          "$gt" -> Json.toJson(eventByStartTime.startTime),
          "$lt" -> Json.toJson(eventByStartTime.before)
        )) ++ Queries.notMarkedForDeletion
  }

  implicit val eventsByArtistFormat = new OWrites[EventsByArtist] {
    override def writes(eventsByArtist: EventsByArtist): JsObject =
      Json
        .obj(
          "artist.name" -> eventsByArtist.artist.name
        )
        .deepMerge(
          eventsByArtist.byStartTime
            .map(l => Json.toJson(l).as[JsObject])
            .getOrElse(Json.obj())
        ) ++ Queries.notMarkedForDeletion
  }

  implicit val eventsByVenueFormat = new OWrites[EventsByVenue] {
    override def writes(eventsByVenue: EventsByVenue): JsObject =
      Json
        .obj(
          "venue.name" -> eventsByVenue.venue.name,
          "venue.location" -> Json.toJson(eventsByVenue.venue.location)
        )
        .deepMerge(
          eventsByVenue.byStartTime
            .map(l => Json.toJson(l).as[JsObject])
            .getOrElse(Json.obj())
        ) ++ Queries.notMarkedForDeletion
  }

}
