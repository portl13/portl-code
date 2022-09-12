package com.portl.test

import akka.stream.Materializer
import com.portl.admin.models.internal
import com.portl.admin.models.internal.InvalidEventException
import com.portl.admin.models.ticketmaster.remote.SearchResult
import com.portl.admin.models.ticketmaster.v1.Event
import com.portl.admin.services.integrations.TicketmasterService
import com.portl.test.services.MappableEventSourceTests
import play.api.libs.json.{JsObject, Json, OFormat}

import scala.io.Source

case class FeedTest(events: List[Event])

object FeedTest {
  implicit val eventFormat: OFormat[FeedTest] = Json.format[FeedTest]
}

class TicketmasterSpec extends PortlBaseTest with MappableEventSourceTests[Event] {
  override val service = injectorObj[TicketmasterService]
  override implicit val materializer: Materializer = injectorObj[Materializer]

  "Ticketmaster serializers" should {
    "parse ticketmaster responses" in {
      // The string argument given to getResource is a path relative to
      // the resources directory.
      val storedResponses = List(
        "ticketmaster-9rb6x50-20180112.json",
        "ticketmaster-chicago-20180222.json",
        "ticketmaster-phoenix-20180223.json"
      )

      storedResponses foreach { storedResponse =>
        val resource = getClass.getResource(s"/data/$storedResponse")
        val source = Source.fromURL(resource)
        val content = source.getLines().mkString
        val parsed = try {
          Json.parse(content).as[SearchResult]
        } finally {
          source.close()
        }

        parsed._embedded mustBe defined
        parsed._embedded
          .map(_.events)
          .foreach { events =>
            events mustBe a[List[_]]
            events must not be empty
            events.foreach(e => e.mustBe(a[JsObject]))
          }
      }
      succeed
    }

    "parse ticketmaster v1 events to portl events if valid" in {
      val resource = getClass.getResource(s"/ticketmaster/eventFeed-20180409-head.json")
      val source = Source.fromURL(resource)
      val content = source.getLines().mkString
      val parsed = Json.parse(content).as[FeedTest]
      parsed.events
        .flatMap { json =>
          try {
            Some(json.toPortl)
          } catch {
            case e: InvalidEventException => None
          }
        }
        .map(_ mustBe an[internal.Event])
      succeed
    }
  }

  "Ticketmaster Event" must {
    "use the artist image as a fallback" in {
      val event = Json.parse(TestJSON.ticketmasterEvent).as[Event]
      // assumption: event has no defined image, but the artist does
      event.eventImageUrl mustBe empty
      event.artist.map(_.imageUrl).find(_.nonEmpty) mustBe defined
      event.toPortl.imageUrl mustEqual event.artist.map(_.imageUrl)
    }
  }

  "Ticketmaster service" should {

    "upcomingEventsSource" should {
      val futureId = "future"
      val recentId = "recent"
      val pastId = "past"

      def setup = {
        val sampleEvent = Json.parse(TestJSON.ticketmasterEvent).as[Event]
        // "eventStartLocalDate" : "2019-03-08",
        // "eventStartDateTime" : "2019-03-09T02:00:00Z",
        val dateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        val dateFormat = "yyyy-MM-dd"

        val events = Seq(
          sampleEvent.copy(
            eventId = futureId,
            eventStartLocalDate = Some(futureTime.toString(dateFormat)),
            eventStartDateTime = Some(futureTime.toString(dateTimeFormat))),
          sampleEvent.copy(
            eventId = recentId,
            eventStartLocalDate = Some(recentTime.toString(dateFormat)),
            eventStartDateTime = Some(recentTime.toString(dateTimeFormat))),
          sampleEvent.copy(
            eventId = pastId,
            eventStartLocalDate = Some(pastTime.toString(dateFormat)),
            eventStartDateTime = Some(pastTime.toString(dateTimeFormat)))
        )
        service.collection.flatMap(resetCollectionWith(_, events))
      }

      "not include events from more than a day ago" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.eventId) mustNot contain(pastId)
        }
      }

      "include events in the past day" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.eventId) must contain(recentId)
        }
      }

      "include future events" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.eventId) must contain(futureId)
        }
      }
    }
  }
}
