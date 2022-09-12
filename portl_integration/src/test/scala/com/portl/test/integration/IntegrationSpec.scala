package com.portl.test.integration

import com.typesafe.config._
import io.gatling.http.funspec.GatlingHttpFunSpec
import io.gatling.core.Predef._
import io.gatling.http.Predef._
import org.joda.time.{DateTime, DateTimeConstants, DateTimeZone}

class IntegrationSpec extends GatlingHttpFunSpec {
  val conf = ConfigFactory.load()

  override def baseUrl: String = conf.getString("baseUrl")
  def username: String = conf.getString("username")
  def password: String = conf.getString("password")

  override def httpProtocol =
    super.httpProtocol
      .contentTypeHeader("application/json; charset=UTF-8")
      .userAgentHeader(
        "Portl/1.0 (com.portl.app; build:11; iOS 11.4.0) Alamofire/4.7.2")
      .basicAuth(username, password)
      .warmUp(s"$baseUrl/status/buildInfo")

  spec {
    http("Fetch category list")
      .get("/categories")
      .check(status.is(200))
  }
  spec {
    import IntegrationSpec._

    http("Search music in NYC")
      .post("/events/search")
      .body(StringBody(
        s"""{"page":0,"pageSize":100,"categories":["$musicCategory"],"maxDistanceMiles":25,"startingAfter":$thisFriday,"location":{"lng":$newYorkLng,"lat":$newYorkLat}}"""))
      .check(eventIds.exists)
  }
}

object IntegrationSpec {
  val newYorkLat = 40.6635
  val newYorkLng = -73.9387
  val thisFriday = DateTime.now
    .withDayOfWeek(DateTimeConstants.FRIDAY)
    .withHourOfDay(17)
    .withZone(DateTimeZone.forID("America/Los_Angeles"))
    .getMillis / 1000
  val musicCategory = "Music"

  val eventIds = jsonPath("$.items[*].event.id").ofType[String]
}
