package com.portl.test

import akka.stream.Materializer
import com.portl.admin.models.eventbrite.Event
import com.portl.admin.models.eventbrite.remote.LocationBasedSearchResult
import com.portl.admin.services.integrations.EventbriteService
import com.portl.test.services.MappableEventSourceTests
import play.api.libs.json.{JsObject, Json}

class EventbriteSpec extends PortlBaseTest with MappableEventSourceTests[Event] {
  override val service = injectorObj[EventbriteService]
  override implicit val materializer: Materializer = injectorObj[Materializer]

  "EventbriteService" should {
    "upcomingEventsSource" should {
      val futureId = "future"
      val recentId = "recent"
      val pastId = "past"

      def setup = {
        val sampleEvent = Json.parse(TestJSON.eventbriteEvent).as[Event]
        // 	"start.local" : "2018-07-21T09:30:00",
        val dateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss"

        val events = Seq(
          sampleEvent.copy(id = futureId, start = sampleEvent.start.copy(local = futureTime.toString(dateTimeFormat))),
          sampleEvent.copy(id = recentId, start = sampleEvent.start.copy(local = recentTime.toString(dateTimeFormat))),
          sampleEvent.copy(id = pastId, start = sampleEvent.start.copy(local = pastTime.toString(dateTimeFormat))),
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

  "Eventbrite serializers" should {
    "parse eventbrite responses" in {
      import scala.io.Source

      // The string argument given to getResource is a path relative to
      // the resources directory.
      val storedResponses = List(
        "eventbrite-houston-20180222.json",
        "eventbrite-newyork-20180222.json",
        "eventbrite-phoenix-20180222.json"
      )

      storedResponses foreach { storedResponse =>
        val resource = getClass.getResource(s"/data/${storedResponse}")
        val source = Source.fromURL(resource)
        val content = source.getLines().mkString
        val parsed = try {
          Json.parse(content).as[LocationBasedSearchResult]
        } finally {
          source.close()
        }

        parsed.events mustBe a[List[_]]
        parsed.events must not be empty
        parsed.events.foreach(e => e.mustBe(a[JsObject]))
      }
      succeed
    }
  }
}
