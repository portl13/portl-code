package com.portl.test

import play.api.test.Helpers._
import play.api.test._
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.Future

/**
  * Functional tests start a Play application internally, available
  * as `app`.
  */
class FunctionalSpec extends PortlBaseTest {

  val reactiveMongoApi = injectorObj[ReactiveMongoApi]
  def collection: Future[JSONCollection] = reactiveMongoApi.database.map(_.collection[JSONCollection]("events"))

  "Routes" must {
    "send 404 on a bad request" in {
      route(app, FakeRequest(GET, "/boum")).map(status(_)) mustBe Some(NOT_FOUND)
    }

    // TODO: Change to a good simple route when we have one
    //"send 200 on a good request" in {
    //  route(app, FakeRequest(GET, "/admin/counts")).map(status(_)) mustBe Some(OK)
    //}

  }

  "Portl MongoDB" must {
    "be accessible" in {
      for {
        db <- reactiveMongoApi.database
        ok <- db.ping()
      } yield {
        ok mustBe true
      }
    }
  }

}
