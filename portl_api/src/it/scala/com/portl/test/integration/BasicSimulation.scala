package com.portl.test.integration

import com.portl.commons.models.EventCategory

import scala.concurrent.duration._
import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.jdbc.Predef._
import org.joda.time.{DateTime, DateTimeConstants, DateTimeZone}
import org.slf4j.LoggerFactory

import scala.util.Random

class BasicSimulation extends Simulation {

  private val log = LoggerFactory.getLogger(getClass)

  // TODO manage this config
  val username = "loadtests"
  val password = "5a605759-6d8c-11e8-95b1-a45e60e9b8cf"
  val baseURL = "http://portl.local"

  val httpProtocol = http
    .baseURL(baseURL)
    .inferHtmlResources()
    .acceptHeader("application/json; charset=UTF8")
    .contentTypeHeader("application/json; charset=UTF-8")
    .acceptEncodingHeader("gzip;q=1.0, compress;q=0.5")
    .acceptLanguageHeader("en;q=1.0")
    .userAgentHeader("Portl/1.0 (com.portl.app; build:11; iOS 11.4.0) Alamofire/4.7.2")
    .basicAuth(username, password)
    .warmUp(s"$baseURL/status/buildInfo")

  object Configuration {
    val userActionPauseMin = 3.seconds
    val userActionPauseMax = 10.seconds

    val categoryCount = 5
    val allCategories = EventCategory.values.map(_.toString)
    val defaultCategories = allCategories.take(categoryCount)
    val categoriesFeeder = Iterator.continually {
      // TODO : How many categories do users really use? Which ones? This is problematic because to execute requests
      // in parallel we need to know how many we want to execute up front. https://github.com/gatling/gatling/issues/2336
      // pick a random 5 categories
      Map("categories" -> Random.shuffle(allCategories).take(categoryCount))
    }
    val locationFeeder = LocalDataService.cities.toIndexedSeq.map { city =>
      Map("latitude" -> city.lat, "longitude" -> city.lng)
    }
    // TODO : Friday at 5pm PST is an arbitrary choice. Consider something that better models user behavior.
    val thisFriday = DateTime.now
      .withDayOfWeek(DateTimeConstants.FRIDAY)
      .withHourOfDay(17)
      .withZone(DateTimeZone.forID("America/Los_Angeles"))
    val startTimeFeeder = {
      (1 to 6).map(thisFriday.minusWeeks).map { d =>
        Map("futureStartTime" -> d.getMillis / 1000)
      }
    }
  }

  object Actions {
    def eventSearchRequest(categoryIndex: Int) =
      http("eventSearch")
        .post("/events/search")
        .body(StringBody(
          s"""{"page":0,"pageSize":100,"categories":["$${categories($categoryIndex)}"],"maxDistanceMiles":25,"startingAfter":$${futureStartTime},"location":{"lng":$${longitude},"lat":$${latitude}}}"""))

    def defaultEventSearch = {
      // Note: I think this is the best we can do to model the real app's behavior, which parallelizes requests for all the
      // user's selected categories. This makes the first request, and then all the others in parallel.
      eventSearchRequest(0)
        .resources(
          (1 until Configuration.categoryCount).map(eventSearchRequest): _*
        )
        // Note: we're capturing event ids just from the first (outer) event search response.
        // The 'resources' requests all share the same session snapshot so we don't get an opportunity to append as those
        // come back (at least without some kind of complicated aggregation step afterward).
        // This should be fine - it just means that when we randomly drill into an event detail it will be one of the
        // events from the first category.
        .check(
          jsonPath("$.items[*].event.id")
            .ofType[String]
            .findAll
            .saveAs("eventIds"))
    }

    def detailRequest(entityType: String, entityId: String) =
      http(s"${entityType}Detail")
        .post(s"/${entityType}s/byId")
        .body(StringBody(s"""{"identifier":"$entityId"}"""))

    def getRandomEventDetail = doIf("${eventIds.exists()}") {
      exec(detailRequest("event", "${eventIds.random()}"))
    }

    def pokeAroundInRandomEvent = doIf("${eventIds.exists()}") {
      exec(
        detailRequest("event", "${eventIds.random()}")
          .check(jsonPath("$.artist.id").ofType[String].find.optional.saveAs("artistId"))
          .check(jsonPath("$.venue.id").ofType[String].find.optional.saveAs("venueId"))
      ).doIf("${venueId.exists()}") {
          pause(Configuration.userActionPauseMin, Configuration.userActionPauseMax).exec(
            detailRequest("venue", "${venueId}"))
        }
        .doIf("${artistId.exists()}") {
          pause(Configuration.userActionPauseMin, Configuration.userActionPauseMax)
            .exec(detailRequest("artist", "${artistId}"))
        }
    }
  }

  object Scenarios {
    // scenario: discovery (one search location, default start time)
    val discovery = scenario("Discovery")
      .feed(Configuration.locationFeeder.random)
      .exec(_.set("categories", Configuration.defaultCategories))
      .feed(Configuration.startTimeFeeder.random)
      .exec(Actions.defaultEventSearch)
      .forever {
        pace(Configuration.userActionPauseMax).exec(exitBlockOnFail(Actions.pokeAroundInRandomEvent))
      }

    // scenario: vacation plan (change search location, future start time)
  }

  setUp(Scenarios.discovery.inject(rampUsers(1).over(20.seconds)))
    .maxDuration(2 minutes)
    .protocols(httpProtocol)
}
