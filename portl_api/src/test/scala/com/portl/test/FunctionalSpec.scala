package com.portl.test

import play.api.libs.json.{JsObject, JsSuccess}
import play.api.test.Helpers._
import play.api.test._
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.play.json.collection.JSONCollection
import com.portl.api.services.EventService
import org.joda.time.DateTime

import scala.concurrent.Future

/**
  * Functional tests start a Play application internally, available
  * as `app`.
  */
class FunctionalSpec extends PortlBaseTest with DataGenerator {

  val reactiveMongoApi = injectorObj[ReactiveMongoApi]
  def collection: Future[JSONCollection] = reactiveMongoApi.database.map(_.collection[JSONCollection]("events"))

  "Routes" must {
    "send 404 on a bad request" in {
      route(app, FakeRequest(GET, "/boum")).map(status(_)) mustBe Some(NOT_FOUND)
    }

    "send 200 on a good request" in {
      route(app, FakeRequest(GET, "/status/dbHealth")).map(status(_)) mustBe Some(OK)
    }

  }

  "Event Service" must {
    "allow retrieving events" in {
      val eventService = injectorObj[EventService]
      for {
        _ <- eventService.insert(TestObjects.storedEvent())
        events <- eventService.all()
      } yield {
        events mustNot be(empty)
      }
    }
  }

  "Event search endpoint" must {
    "serialize location as an object with latitude and longitude" in {
      val now = DateTime.now
      val newEvent = createEventAt(presetLocations.eugene, now)
      val service = injectorObj[EventService]
      val postBody =
        s"""
          |{"location":{"lat":${presetLocations.eugene.latitude},"lng":${presetLocations.eugene.longitude}},
          |"startingAfter":${now.minusDays(1).getMillis / 1000},
          |"page":0,
          |"pageSize":1}"
        """.stripMargin
      for {
        collection <- service.collection
        _ <- resetCollection(collection)
        _ <- service.insert(newEvent)
      } yield {
        val responseOption = route(
          app,
          FakeRequest(
            POST,
            "/events/search",
            FakeHeaders(
              Seq(
                "Authorization" -> "Basic aU9TdjI6OWM1YTczYmItMDMxMy00ZDI2LThhYzItZGZmNDc1YWRmNGIz",
                "Content-Type" -> "application/json"
              )),
            postBody
          )
        )
        responseOption mustBe defined
        val responseContent = responseOption.map(contentAsJson).get
        println(responseContent)

        (responseContent \ "items").validate[Seq[JsObject]] match {
          case JsSuccess(events, _) =>
            events must have length 1
            val eventWrapper = events.head
            (eventWrapper \ "event").validate[JsObject] match {
              case JsSuccess(retrievedEvent, _) =>
                (retrievedEvent \ "venue" \ "location" \ "latitude").validate[Double] match {
                  case JsSuccess(lat, _) => lat mustEqual newEvent.venue.location.latitude
                  case _                 => fail("venue.location.lat was not a double")
                }
                (retrievedEvent \ "venue" \ "location" \ "longitude").validate[Double] match {
                  case JsSuccess(lng, _) => lng mustEqual newEvent.venue.location.longitude
                  case _                 => fail("venue.location.lng was not a double")
                }
              case _ => fail("eventWrapper.event was not an object")
            }
          case _ => fail("response.items was not a list of objects")
        }
      }
    }
  }

}
