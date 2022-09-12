package com.portl.api.controllers

import java.util.Date

import javax.inject.Inject
import com.portl.api.build.PortlApiBuildInfo
import com.portl.commons.services.StatusService
import play.api.libs.json.{Json, OWrites}
import play.api.mvc.{AbstractController, ControllerComponents}
import reactivemongo.api.ReadPreference

import scala.concurrent.ExecutionContext

class StatusController @Inject()(cc: ControllerComponents,
                                 statusService: StatusService,
                                 implicit val ec: ExecutionContext)
    extends AbstractController(cc) {

  def buildInfo = Action {
    Ok(PortlApiBuildInfo.toJson)
  }

  def dbHealth = Action.async {
    val date = new Date().getTime
    for {
      db <- statusService.reactiveMongoApi.database
      ok <- db.ping(ReadPreference.secondaryPreferred)
    } yield {
      val result = Json.toJson(ReadOnlyStatusResult(read = ok, date))
      if (ok) Ok(result)
      else InternalServerError(result)
    }
  }

  def checkIndexes = Action.async {
    statusService.checkIndexes map {
      case true  => Ok("indexes validated")
      case false => Ok("index validation failed")
    }
  }
}

case class ReadOnlyStatusResult(read: Boolean, date: Long)
object ReadOnlyStatusResult {
  implicit val writes: OWrites[ReadOnlyStatusResult] = Json.writes[ReadOnlyStatusResult]
}
