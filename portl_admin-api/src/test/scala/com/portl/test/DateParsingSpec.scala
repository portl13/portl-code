package com.portl.test

import com.portl.admin.models.eventbrite.remote.ContinuationBasedSearchResult
import com.portl.admin.models.ticketfly.remote.SearchResult
import com.portl.admin.models.{eventbrite, ticketfly}
import play.api.libs.json.Json

import scala.io.Source

class DateParsingSpec extends PortlBaseTest {
  "parse ticketmaster dates correctly" in {
    val resource = getClass.getResource(s"/ticketmaster/eventFeed-20180409-head.json")
    val source = Source.fromURL(resource)
    val content = source.getLines().mkString
    val parsed = Json.parse(content).as[FeedTest]
    val event = parsed.events.find(event => event.eventId == "Z7r9jZ1AeGwuI").get
    val portlEvent = event.toPortl
    portlEvent.startDateTime.dayOfMonth().get() must equal(20)
    portlEvent.startDateTime.monthOfYear().get() must equal(6)
    portlEvent.startDateTime.year().get() must equal(2018)
    portlEvent.startDateTime.hourOfDay().get() must equal(3)
    portlEvent.startDateTime.minuteOfHour().get() must equal(30)
    portlEvent.localStartDate must equal("2018-06-19")
    portlEvent.timezone must equal("America/Los_Angeles")
  }
  "parse eventbrite dates correctly" in {
    val resource = getClass.getResource(s"/eventbrite/eventFeed-20180522.json")
    val source = Source.fromURL(resource)
    val content = source.getLines().mkString
    val parsed = Json.parse(content).as[ContinuationBasedSearchResult].events.map(_.as[eventbrite.Event])
    val event = parsed.find(e => e.id == "46335935029").get
    val portlEvent = event.toPortl
    portlEvent.startDateTime.dayOfMonth().get() must equal(25)
    portlEvent.startDateTime.monthOfYear().get() must equal(5)
    portlEvent.startDateTime.year().get() must equal(2018)
    portlEvent.startDateTime.hourOfDay().get() must equal(1)
    portlEvent.startDateTime.minuteOfHour().get() must equal(30)
    portlEvent.localStartDate must equal("2018-05-24")
    portlEvent.timezone must equal("America/Toronto")
  }
  "parse ticketfly dates correctly" in {
    val resource = getClass.getResource(s"/ticketfly/upcoming-20180522-head.json")
    val source = Source.fromURL(resource)
    val content = source.getLines().mkString
    val parsed = Json.parse(content).as[SearchResult].events.map(_.as[ticketfly.Event])
    val event = parsed.find(e => e.id == 1269263).get
    val portlEvent = event.toPortl
    portlEvent.startDateTime.dayOfMonth().get() must equal(31)
    portlEvent.startDateTime.monthOfYear().get() must equal(3)
    portlEvent.startDateTime.year().get() must equal(2017)
    portlEvent.startDateTime.hourOfDay().get() must equal(14)
    portlEvent.startDateTime.minuteOfHour().get() must equal(0)
    portlEvent.localStartDate must equal("2017-03-31")
    portlEvent.timezone must equal("America/New_York")
  }
}
