package com.portl.test
import java.util.UUID

import akka.stream.Materializer
import akka.stream.scaladsl.Sink
import com.portl.admin.models.internal
import com.portl.admin.models.portlAdmin.{Artist, Event, Venue}
import com.portl.admin.services.{AdminEventSourceService, ArtistCrudService, EventCrudService, VenueCrudService}
import com.portl.commons.models.Location
import com.portl.test.services.MappableEventSourceTests
import org.joda.time.{DateTime, DateTimeZone}
import play.api.libs.json.{Json, OFormat}

import scala.concurrent.Future

class AdminEventSourceServiceSpec extends PortlBaseTest with MappableEventSourceTests[internal.Event] {
  val sourceService = injectorObj[AdminEventSourceService]
  val eventService = injectorObj[EventCrudService]
  val venueService = injectorObj[VenueCrudService]
  val artistService = injectorObj[ArtistCrudService]

  implicit val materializer = injectorObj[Materializer]
  override val service: AdminEventSourceService = sourceService

  def createArtist(): Artist = {
    Json.parse(TestJSON.portlAdminArtist).as[Artist]
  }

  def createVenue(location: Location): Venue = {
    // Use external Location formatter and build a new external Venue formatter.
    import com.portl.commons.serializers.External._
    implicit val format: OFormat[Venue] = Json.format[Venue]
    val venue = TestJSON.portlAdminVenue
    Json
      .parse(venue)
      .as[Venue]
      .copy(location = location)
  }

  def createEvent(startDateTime: DateTime, venueId: UUID, artist: Option[Artist] = None): Event = {
    val event = TestJSON.portlAdminEvent
    Json
      .parse(event)
      .as[Event]
      .copy(startDateTime = startDateTime)
      .copy(artistId = artist.flatMap(_.id))
      .copy(venueId = venueId)
  }

  def createEvent(startDateTime: DateTime, location: Location): Future[Event] = {
    for {
      venue <- venueService.create(createVenue(location))
      venueId = venue.id.getOrElse(throw new Exception("missing id on newly created venue"))
      artist <- artistService.create(createArtist())
      event <- eventService.create(createEvent(startDateTime, venueId, Some(artist)))
    } yield event
  }

  "converted events" should {
    "have a valid localStartDate" in {
      val year = 2018
      val month = 11
      val day = 16
      val dt = new DateTime(year, month, day, 13, 44, DateTimeZone.forID("America/Los_Angeles"))
      val here = Location(-123.45, 44.05)
      for {
        _ <- eventService.collection.flatMap(resetCollection)
        event <- createEvent(dt, here)
        artist <- artistService.getById(event.artistId.get)
        venue <- venueService.getById(event.venueId)
        portlEvent = event.toPortl(venue.toPortl, Some(artist.toPortl))
      } yield {
        portlEvent.localStartDate mustEqual s"$year-$month-$day"
      }
    }
  }

  "allEventsSource" should {
    "yield all events" in {
      val now = DateTime.now
      val yesterday = now.minusDays(1)
      val tomorrow = now.plusDays(1)
      val here = Location(-123.45, 44.05)
      for {
        _ <- eventService.collection.flatMap(resetCollection)
        e1 <- createEvent(now, here)
        e2 <- createEvent(yesterday, here)
        e3 <- createEvent(tomorrow, here)
        eventSource <- sourceService.allEventsSource
        allEvents <- eventSource.runWith(Sink.collection[internal.Event, Set[internal.Event]])
      } yield allEvents.map(_.externalId.identifierOnSource) mustEqual Set(e1, e2, e3).flatMap(_.id).map(_.toString)
    }
  }

  "upcomingEventsSource" should {
    // return (pastId, recentId, futureId)
    def setup: Future[Seq[String]] = {
      val here = Location(-123.45, 44.05)

      for {
        c <- eventService.collection
        _ <- resetCollection(c)
        futureEvent <- createEvent(futureTime, here)
        recentEvent <- createEvent(recentTime, here)
        pastEvent <- createEvent(pastTime, here)
      } yield Seq(pastEvent, recentEvent, futureEvent).map(_.id.get.toString)
    }

    "not include events from more than a day ago" in {
      for {
        Seq(pastId, recentId, futureId) <- setup
        future <- collectUpcomingEvents
      } yield {
        future.map(_.externalId.identifierOnSource) mustNot contain(pastId)
      }
    }

    "include events in the past day" in {
      for {
        Seq(pastId, recentId, futureId) <- setup
        future <- collectUpcomingEvents
      } yield {
        future.map(_.externalId.identifierOnSource) must contain(recentId)
      }
    }

    "include future events" in {
      for {
        Seq(pastId, recentId, futureId) <- setup
        future <- collectUpcomingEvents
      } yield {
        future.map(_.externalId.identifierOnSource) must contain(futureId)
      }
    }
  }
}
