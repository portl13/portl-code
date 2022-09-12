package com.portl.test

import java.nio.file.Paths

import akka.actor.ActorSystem
import akka.stream.{ActorMaterializer, Materializer}
import akka.stream.scaladsl.{FileIO, Sink}
import com.portl.admin.streams.JSONFeed
import play.api.libs.json.JsObject

class JSONFeedSpec extends PortlBaseTest {
  implicit val system = ActorSystem("TestSystem")
  implicit val materializer: Materializer = ActorMaterializer()

  "JSONFeed" should {
    "work for songkick data" in {
      val resource = getClass.getResource(s"/songkick/upcoming-20180719.head.json.gz")
      val streamFieldName = "event"
      val eventCount = 50

      val source = FileIO.fromPath(Paths.get(resource.getPath))
      val unzipped = JSONFeed(source, streamFieldName)

      val result = unzipped.valuesBeforeStreamField()
      result mustBe a[JsObject]

      for {
        events <- unzipped.streamFieldContents().runWith(Sink.seq)
      } yield {
        events.length mustEqual eventCount
      }
    }

    "work for recent songkick data" in {
      val resource = getClass.getResource(s"/songkick/recent_upcoming-20180724-sample.json.gz")
      // Original response had 49084 events. This file is edited to include a random sample of 500 of them.
      // {"resultsPage": {"totalEntries": 500, "perPage": 500, "page": 1, "results": {"event": [ ... ]}}}
      val streamFieldName = "event"
      val eventCount = 500

      val source = FileIO.fromPath(Paths.get(resource.getPath))
      val unzipped = JSONFeed(source, streamFieldName)

      val result = unzipped.valuesBeforeStreamField()
      result mustBe a[JsObject]
      for {
        events <- unzipped.streamFieldContents().runWith(Sink.seq)
      } yield {
        events.length mustEqual eventCount
      }
    }

    "work for fabricated short songkick event data" in {
      val resource = getClass.getResource(s"/songkick/short_events.json.gz")
      val eventCount = 10000
      val streamFieldName = "event"

      val source = FileIO.fromPath(Paths.get(resource.getPath))
      val unzipped = JSONFeed(source, streamFieldName)

      val result = unzipped.valuesBeforeStreamField()
      result mustBe a[JsObject]

      // Now try iterating through the events
      for {
        events <- unzipped.streamFieldContents().runWith(Sink.seq)
      } yield {
        val expected = 0 to 9999
        val actual = events map { e =>
          (e \ "index").as[Int]
        }
        val missing = (expected.toSet -- actual.toSet).toSeq.sorted
        println(s"missing: $missing")
        events.length mustEqual eventCount
      }
    }

    "work for fabricated long songkick event data" in {
      // 9/10
      val resource = getClass.getResource(s"/songkick/long_events.json.gz")
      val eventCount = 10
      val streamFieldName = "event"

      val source = FileIO.fromPath(Paths.get(resource.getPath))
      val unzipped = JSONFeed(source, streamFieldName)

      val result = unzipped.valuesBeforeStreamField()
      result mustBe a[JsObject]

      // Now try iterating through the events
      for {
        events <- unzipped.streamFieldContents().runWith(Sink.seq)
      } yield {
        events.length mustEqual eventCount
      }
    }

    "work for ticketmaster data" in {
      val resource = getClass.getResource(s"/ticketmaster/eventFeed-20180409-head.json.gz")
      val streamFieldName = "events"
      val eventCount = 49

      val source = FileIO.fromPath(Paths.get(resource.getPath))
      val unzipped = JSONFeed(source, streamFieldName)

      val result = unzipped.valuesBeforeStreamField()
      result mustBe a[JsObject]
      // {"events": [
      result mustEqual JsObject.empty

      for {
        count <- unzipped.streamFieldContents().runFold(0)((count, _) => count + 1)
      } yield {
        count mustEqual eventCount
      }
    }
  }
}
