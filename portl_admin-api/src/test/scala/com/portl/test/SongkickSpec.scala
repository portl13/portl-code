package com.portl.test

import java.nio.file.Paths
import java.util.zip.GZIPInputStream

import akka.stream.Materializer
import akka.stream.scaladsl.{FileIO, Sink, Source, StreamConverters}
import com.portl.admin.models.songkick
import com.portl.admin.models.songkick.Event
import com.portl.admin.services.integrations.SongkickService
import com.portl.test.services.MappableEventSourceTests
import play.api.libs.json._

class SongkickSpec extends PortlBaseTest with MappableEventSourceTests[Event] {

  override val service: SongkickService = injectorObj[SongkickService]
  override implicit lazy val materializer: Materializer = injectorObj[Materializer]

  "bulkUpsert" should {
    "work for feed data in batches of 100" in {
      val batchSize = 100
      val parallelism = 4
      val resource = getClass.getResource(s"/songkick/recent_upcoming-20180724-sample.json.gz")
      val source = FileIO.fromPath(Paths.get(resource.getPath))
      implicit val materializer: Materializer = service.materializer
      val responseObject = Json.parse(new GZIPInputStream(source.runWith(StreamConverters.asInputStream())))
      val events = (responseObject \ "resultsPage" \ "results" \ "event").as[List[JsObject]]

      for {
        c <- service.collection
        _ <- resetCollection(c)
        _ <- Source(events)
          .grouped(batchSize)
          .mapAsync(parallelism) { events =>
            service.bulkUpsert(events)
          }
          .runWith(Sink.ignore)
        count1 <- service.countAllEvents
        _ <- Source(events)
          .grouped(batchSize)
          .mapAsync(parallelism) { events =>
            service.bulkUpsert(events)
          }
          .runWith(Sink.ignore)
        count2 <- service.countAllEvents
      } yield {
        count1 mustEqual events.length
        count2 mustEqual events.length
      }
    }
  }

  "Songkick service" should {
    "upcomingEventsSource" should {
      val futureId = 123
      val recentId = 456
      val pastId = 789

      def setup = {
        val sampleEvent = Json.parse(TestJSON.songkickEvent).as[Event]
        // 	"start.date" : "2018-08-10",
        val dateTimeFormat = "yyyy-MM-dd"

        val events = Seq(
          sampleEvent.copy(id = futureId, start = sampleEvent.start.copy(date = futureTime.toString(dateTimeFormat))),
          sampleEvent.copy(id = recentId, start = sampleEvent.start.copy(date = recentTime.toString(dateTimeFormat))),
          sampleEvent.copy(id = pastId, start = sampleEvent.start.copy(date = pastTime.toString(dateTimeFormat))),
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

  "Songkick serializers" should {
    "parse a songkick api response" in {
      // The string argument given to getResource is a path relative to
      // the resources directory.
      val resource = getClass.getResource("/data/songkick-eugene-20180222.json")
      val source = scala.io.Source.fromURL(resource)
      val content = source.getLines().mkString
      val parsed = try {
        Json.parse(content).as[songkick.remote.SearchResult]
      } finally {
        source.close()
      }

      val eventsOption = parsed.resultsPage.results.event
      eventsOption mustBe defined
      val events = eventsOption.get
      events mustBe a[List[_]]
      events must not be empty
      events.foreach(e => {
        e.mustBe(a[JsObject])
        e.validate[songkick.Event] mustBe a[JsSuccess[_]]
      })
      succeed
    }
  }
}
