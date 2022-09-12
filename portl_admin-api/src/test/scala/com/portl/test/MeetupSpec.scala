package com.portl.test

import akka.stream.Materializer
import com.portl.admin.models.internal
import com.portl.admin.models.meetup.Event
import com.portl.admin.models.meetup.remote.SearchResult
import com.portl.admin.services.integrations.MeetupService
import play.api.libs.json.Json
import com.portl.commons.models.{EventCategory, MarkupType}
import com.portl.test.services.MappableEventSourceTests
import org.joda.time.DateTime

import scala.io.Source

class MeetupSpec extends PortlBaseTest with MappableEventSourceTests[Event] {
  override val service: MeetupService = injectorObj[MeetupService]
  override implicit val materializer: Materializer = injectorObj[Materializer]

  def meetupEvent =
    Json.parse(TestJSON.meetupEvent).as[Event]

  "MeetupService" should {

    "upcomingEventsSource" should {
      val futureId = "future"
      val recentId = "recent"
      val pastId = "past"

      def setup = {
        val sampleEvent = Json.parse(TestJSON.meetupEvent).as[Event]

        val events = Seq(
          sampleEvent.copy(id = futureId, time = futureTime.getMillis),
          sampleEvent.copy(id = recentId, time = recentTime.getMillis),
          sampleEvent.copy(id = pastId, time = pastTime.getMillis),
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

  "Meetup serializers" should {
    "parse meetup responses" in {
      val resource = getClass.getResource("/meetup/open-events-head-20180531.json")
      val source = Source.fromURL(resource)
      val content = source.getLines().mkString
      val parsed = try {
        Json.parse(content).as[SearchResult]
      } finally {
        source.close()
      }

      val events = parsed.results.map(event => event.as[Event])
      events mustBe a[List[_]]
      events must not be empty
      events.size must equal(200)
      events.foreach(e => e.mustBe(a[Event]))
      succeed
    }
  }

  "Meetup events" should {
    "convert to portl events" in {
      val portlEvent = meetupEvent.toPortl
      portlEvent mustBe an[internal.Event]
    }

    "convert with correct localStartDate" in {
      val portlEvent = meetupEvent.toPortl
      val startDate = DateTime.parse(portlEvent.localStartDate)
      startDate.getYear mustEqual 2019
      startDate.getMonthOfYear mustEqual 1
      startDate.getDayOfMonth mustEqual 1
    }

    "convert with correct description" in {
      val portlEvent = meetupEvent.toPortl
      portlEvent.description mustBe defined
      portlEvent.description.get.markupType mustEqual MarkupType.HTML
    }

    "convert with event url" in {
      val portlEvent = meetupEvent.toPortl
      portlEvent.url mustBe defined
      portlEvent.url.get must not be empty
    }

    "not all be categorized as 'community'" in {
      val portlEvent = meetupEvent.toPortl
      portlEvent.categories must not contain EventCategory.Community
    }
  }
}
