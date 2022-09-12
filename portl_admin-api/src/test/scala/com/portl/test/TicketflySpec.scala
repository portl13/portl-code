package com.portl.test

import akka.stream.Materializer
import com.portl.admin.models.ticketfly.Event
import com.portl.admin.models.ticketfly.remote.SearchResult
import com.portl.admin.services.integrations.TicketflyService
import com.portl.test.services.MappableEventSourceTests
import play.api.libs.json._

import scala.io.Source

class TicketflySpec extends PortlBaseTest with MappableEventSourceTests[Event] {
  override val service: TicketflyService = injectorObj[TicketflyService]
  override implicit val materializer: Materializer = injectorObj[Materializer]

  "Ticketfly" should {
    "parse ticketfly responses" in {
      // The string argument given to getResource is a path relative to
      // the resources directory.
      val storedResponses = List(
        "upcoming-20180418.json"
      )

      storedResponses foreach { storedResponse =>
        val resource = getClass.getResource(s"/ticketfly/${storedResponse}")
        val source = Source.fromURL(resource)
        val content = source.getLines().mkString
        val parsed = try {
          Json.parse(content).as[SearchResult]
        } finally {
          source.close()
        }

        parsed.events mustBe a[List[_]]
        parsed.events must not be empty
        parsed.events.foreach { e =>
          e.mustBe(a[JsObject])
          e.as[Event] mustBe an[Event]
        }
      }
      succeed
    }
  }

  "Ticketfly Events" must {
    "use the artist image as a fallback" in {
      val event = Json.parse(TestJSON.ticketflyEvent).as[Event]
      // assumption: event has no defined image, but the artist does
      event.image must not be defined
      event.artist.flatMap(_.image) mustBe defined
      event.toPortl.imageUrl mustEqual event.artist.flatMap(_.imageURL)
    }
  }

  "TicketflyService" should {
    "upcomingEventsSource" should {
      val futureId = 123
      val recentId = 456
      val pastId = 789

      def setup = {
        val sampleEvent = Json.parse(TestJSON.ticketflyEvent).as[Event]
        // 	"startDate" : "2018-10-09 20:00:00",
        val dateTimeFormat = "yyyy-MM-dd' 'HH:mm:ss"

        val events = Seq(
          sampleEvent.copy(id = futureId, startDate = futureTime.toString(dateTimeFormat)),
          sampleEvent.copy(id = recentId, startDate = recentTime.toString(dateTimeFormat)),
          sampleEvent.copy(id = pastId, startDate = pastTime.toString(dateTimeFormat))
        )
        service.collection.flatMap(resetCollectionWith(_, events))
      }

      "not include events from more than a day ago" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.id) mustNot contain(pastId)
        }
      }

      "include events in the past day" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.id) must contain(recentId)
        }
      }

      "include future events" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.id) must contain(futureId)
        }
      }
    }
  }
}
