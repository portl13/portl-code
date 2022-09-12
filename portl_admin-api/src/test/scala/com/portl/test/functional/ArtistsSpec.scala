package com.portl.test.functional

import java.net.URLEncoder

import com.portl.admin.services.ArtistCrudService
import com.portl.test.PortlBaseTest
import play.api.libs.json._
import play.api.test.Helpers._
import play.api.test.{FakeHeaders, FakeRequest}
import play.mvc.Http.HeaderNames

class ArtistsSpec extends PortlBaseTest {
  val service = injectorObj[ArtistCrudService]

  private def asyncSetup = service.collection.flatMap(resetCollection)

  "Artist endpoints" must {
    val listEndpoint = "/api/v1/artist"
    val name = "Some artist I want to create"
    val encodedName = URLEncoder.encode(name, "UTF-8")
    val newArtistJSON =
      s"""{
         |  "name":"$name",
         |  "imageUrl":"https://media.staging.portl.com/media/2ba468a0-c052-401f-a968-1ee314d0214b/foo.jpg",
         |  "url":"https://example.com",
         |  "description":""
         |}
         |""".stripMargin

    "work" in asyncSetup.flatMap { _ =>
      val headers = FakeHeaders(Seq(HeaderNames.CONTENT_TYPE -> "application/json"))
      val createRequest = FakeRequest(POST, listEndpoint).withHeaders(headers).withBody(newArtistJSON)
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
      val headers = FakeHeaders(Seq(HeaderNames.CONTENT_TYPE -> "application/json"))
      val createRequest = FakeRequest(POST, listEndpoint).withHeaders(headers).withBody(newArtistJSON)
      route(app, createRequest).map(status(_)) mustBe Some(CREATED)

      // with filter by correct name
      route(app, FakeRequest(GET, s"$listEndpoint?q=$encodedName").withHeaders(headers))
        .map(contentAsJson(_))
        .map { responseJson =>
          (responseJson \ "results").validate[Seq[JsObject]] match {
            case JsSuccess(results, _) => results.length mustEqual 1
            case _                     => fail
          }
        }
        .getOrElse(fail)

      // with filter by incorrect name
      route(app, FakeRequest(GET, s"$listEndpoint?q=Another+artist").withHeaders(headers))
        .map(contentAsJson(_))
        .map { responseJson =>
          (responseJson \ "results").validate[Seq[JsObject]] match {
            case JsSuccess(results, _) => results.length mustEqual 0
            case _                     => fail
          }
        }
        .getOrElse(fail)
    }
  }
}
