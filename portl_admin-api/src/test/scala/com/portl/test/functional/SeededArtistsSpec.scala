package com.portl.test.functional
import com.portl.admin.services.SeededArtistCrudService
import com.portl.test.PortlBaseTest
import play.api.libs.json._
import play.api.test.{FakeHeaders, FakeRequest}
import play.api.test.Helpers._
import play.mvc.Http.HeaderNames

class SeededArtistsSpec extends PortlBaseTest {
  val service = injectorObj[SeededArtistCrudService]

  private def asyncSetup = service.collection.flatMap(resetCollection)

  "SeededArtist endpoints" must {
    val listEndpoint = "/api/v1/seededArtist"

    "work" in asyncSetup.flatMap { _ =>
      val name = "Some artist I want to seed"
      val newSeededArtistJSON = s"""{"name":"$name"}"""
      val headers = FakeHeaders(Seq(HeaderNames.CONTENT_TYPE -> "application/json"))
      val createRequest = FakeRequest(POST, listEndpoint).withHeaders(headers).withBody(newSeededArtistJSON)
      route(app, createRequest).map(status(_)) mustBe Some(CREATED)

      val listRequest = FakeRequest(GET, listEndpoint).withHeaders(headers)
      val result = route(app, listRequest)
      result.map(status(_)) mustBe Some(OK)
      result
        .map(contentAsJson(_))
        .map { responseJson =>
          (responseJson \ "results").validate[Seq[JsObject]] match {
            case JsSuccess(results, _) => results.length mustEqual 1
            case _                     => fail
          }
        }
        .getOrElse(fail)
    }

    "filter by name" in asyncSetup.flatMap { _ =>
      val name = "Some artist I want to seed"
      val newSeededArtistJSON = s"""{"name":"$name"}"""
      val headers = FakeHeaders(Seq(HeaderNames.CONTENT_TYPE -> "application/json"))
      val createRequest = FakeRequest(POST, listEndpoint).withHeaders(headers).withBody(newSeededArtistJSON)
      route(app, createRequest).map(status(_)) mustBe Some(CREATED)

      // with filter by correct name
      route(app, FakeRequest(GET, s"$listEndpoint?name=Some+artist").withHeaders(headers))
        .map(contentAsJson(_))
        .map { responseJson =>
          (responseJson \ "results").validate[Seq[JsObject]] match {
            case JsSuccess(results, _) => results.length mustEqual 1
            case _                     => fail
          }
        }
        .getOrElse(fail)

      // with filter by incorrect name
      route(app, FakeRequest(GET, s"$listEndpoint?name=Another+artist").withHeaders(headers))
        .map(contentAsJson(_))
        .map { responseJson =>
          (responseJson \ "results").validate[Seq[JsObject]] match {
            case JsSuccess(results, _) => results.length mustEqual 1
            case _                     => fail
          }
        }
        .getOrElse(fail)
    }
  }
}
