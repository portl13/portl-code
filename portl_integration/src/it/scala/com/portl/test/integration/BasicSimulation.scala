package com.portl.test.integration

// TODO : remove portl-commons dependency
import com.portl.commons.models.EventCategory
import io.gatling.commons.validation.Success

import scala.concurrent.duration._
import io.gatling.core.Predef._
import io.gatling.http.Predef._
import io.gatling.http.request.builder.RequestBuilder
import io.gatling.jdbc.Predef._
import org.joda.time.{DateTime, DateTimeConstants, DateTimeZone}
import org.slf4j.LoggerFactory

import scala.util.Random

class BasicSimulation extends Simulation {

  private val log = LoggerFactory.getLogger(getClass)

//  val username = "loadtests"
//  val password = "5a605759-6d8c-11e8-95b1-a45e60e9b8cf"
//  val baseURL = "http://portl.local"

  val username = "iOSv2"
  val password = "9c5a73bb-0313-4d26-8ac2-dff475adf4b3"
  val baseURL = "https://api.staging.portl.com"

  val httpProtocol = http
    .baseUrl(baseURL)
    .inferHtmlResources()
    .acceptHeader("application/json; charset=UTF8")
    .contentTypeHeader("application/json; charset=UTF-8")
    .acceptEncodingHeader("gzip;q=1.0, compress;q=0.5")
    .acceptLanguageHeader("en;q=1.0")
    .userAgentHeader(
      "Portl/1.0 (com.portl.app; build:11; iOS 11.4.0) Alamofire/4.7.2")
    .basicAuth(username, password)
    .warmUp(s"$baseURL/status/buildInfo")

  object Configuration {
    val userActionPauseMin = 3.seconds
    val userActionPauseMax = 10.seconds

    val categoryCount = 5
    val allCategories = EventCategory.values.map(_.toString)

    import EventCategory._
    val defaults = IndexedSeq(Music,
                              Community,
                              Theatre,
                              Family,
                              Sports,
                              Comedy,
                              Business,
                              Film).map(_.toString)
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
    val eventIdsFeeder = csv("stagingIds.csv")
    // TODO : Friday at 5pm PST is an arbitrary choice. Consider something that better models user behavior.
    val thisFriday = DateTime.now
      .withDayOfWeek(DateTimeConstants.FRIDAY)
      .withHourOfDay(17)
      .withZone(DateTimeZone.forID("America/Los_Angeles"))
    val startTimeFeeder = {
      (-2 to 4).map(thisFriday.plusWeeks).map { d =>
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

    def singleEventSearch = {
      http("eventSearch")
        .post("/events/search")
        .body(StringBody(
          s"""{"page":0,"pageSize":100,"categories":["$${categories(0)}"],"maxDistanceMiles":25,"startingAfter":$${futureStartTime},"location":{"lng":$${longitude},"lat":$${latitude}}}"""))
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

    def pokeAroundInRandomEvent(
        userActionPauseMin: Duration = Configuration.userActionPauseMin,
        userActionPauseMax: Duration = Configuration.userActionPauseMax) =
      doIf { session =>
        session("eventIds").validate[Seq[String]] match {
          case Success(value) =>
            value.nonEmpty
          case _ => false
        }
      } {
        exec(session => {
          val eventIds = session("eventIds").as[Seq[String]]
          val index = Random.nextInt(eventIds.length)
          session.set("eventId", eventIds(index))
        }).exec(pokeAroundInEvent(userActionPauseMin, userActionPauseMax))
      }

    def pokeAroundInEvent(
        userActionPauseMin: Duration = Configuration.userActionPauseMin,
        userActionPauseMax: Duration = Configuration.userActionPauseMax) =
      exec(
        detailRequest("event", "${eventId}")
          .check(status.is(200))
          .check(
            jsonPath("$.artist.id")
              .ofType[String]
              .optional
              .saveAs("artistId"))
          .check(
            jsonPath("$.venue.id")
              .ofType[String]
              .optional
              .saveAs("venueId"))
      ).doIf("${venueId.exists()}") {
          pause(userActionPauseMax).exec(detailRequest("venue", "${venueId}"))
        }
        .doIf("${artistId.exists()}") {
          pause(userActionPauseMax)
            .exec(detailRequest("artist", "${artistId}"))
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
        pace(Configuration.userActionPauseMax)
          .exec(exitBlockOnFail(Actions.pokeAroundInRandomEvent()))
      }

    val firstLaunch = scenario("First Launch")
      .feed(Configuration.locationFeeder.random)
      .exec(_.set("categories", Configuration.defaultCategories))
      .feed(Configuration.startTimeFeeder.random)
      .exec(Actions.defaultEventSearch)

    val minimalSearch = scenario("Minimal Search")
      .feed(Configuration.locationFeeder.random)
      // 1 category to minimize the up-front search cost
      // we do need to do at least one initial search per user to find some events to start drilling into
      .exec(_.set("categories", Configuration.allCategories.take(1)))
      .feed(Configuration.startTimeFeeder.random)
      .exec(Actions.singleEventSearch)
      .pause(rampTime / 2)
      .forever {
        // have the users take actions quickly
        val pauseMin = 0.milliseconds
        val pauseMax = 50.milliseconds
        exec(exitBlockOnFail(
          Actions.pokeAroundInRandomEvent(pauseMin, pauseMax).pause(pauseMax)))
      }

    val repeatSearch = scenario("Repeated Searches")
      .feed(Configuration.locationFeeder.random)
      .exec(_.set("categories", Configuration.defaultCategories))
      .feed(Configuration.startTimeFeeder.random)
      .forever(
        exec(Actions.singleEventSearch).pause(searchDelay)
      )

    val noSearch = scenario("No Search")
      .forever {
        // have the users take actions quickly
        val pauseMin = 50.milliseconds
        val pauseMax = 500.milliseconds
        feed(Configuration.eventIdsFeeder)
          .exec(exitBlockOnFail(Actions.pokeAroundInEvent(pauseMin, pauseMax)))
          .pause(pauseMax)
      }

  }

//  setUp(Scenarios.firstLaunch.inject(constantUsersPerSec(1).during(200.seconds)))
//    .maxDuration(2 minutes)
//    .protocols(httpProtocol)
//  setUp(
//    Scenarios.minimalSearch.inject(
//      rampUsers(300).during(20.seconds),
//      nothingFor(40.seconds),
//      rampUsers(300).during(5.minutes)
//    ))
//    .maxDuration(10 minutes)
//    .protocols(httpProtocol)

  val userCount = System.getProperties.getProperty("userCount", "100").toInt
  val rampTime =
    System.getProperties.getProperty("rampMinutes", "2").toDouble.minutes
  val maxDuration = System.getProperties
    .getProperty("maxDurationMinutes", "10")
    .toDouble
    .minutes

  val searchDelay = System.getProperties
    .getProperty("searchDelaySeconds", "100")
    .toDouble
    .seconds
  val usersPerSecond =
    System.getProperties.getProperty("usersPerSecond", "1").toInt

//  setUp(
//    Scenarios.minimalSearch.inject(rampUsers(userCount).during(rampTime),
//                                   nothingFor(maxDuration - rampTime)))
//    .maxDuration(maxDuration)
//    .protocols(httpProtocol)
  setUp(
    Scenarios.repeatSearch
      .inject(
        rampUsers(userCount).during(rampTime),
        constantUsersPerSec(usersPerSecond).during(maxDuration - rampTime)))
    .maxDuration(maxDuration)
    .protocols(httpProtocol)

//  setUp(
//    Scenarios.noSearch.inject(rampUsers(userCount).during(rampTime),
//                              rampUsers(userCount * 2).during(rampTime * 20)))
//    .maxDuration(rampTime * 25)
//    .protocols(httpProtocol)
}
