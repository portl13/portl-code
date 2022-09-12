package com.portl.admin.controllers

import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.build.AdminApiBuildInfo
import com.portl.admin.controllers.base.PORTLAdminController
import javax.inject.Inject
import com.portl.commons.services.StatusService
import play.api.libs.json.Json
import play.api.mvc._

import scala.concurrent.ExecutionContext

class StatusController @Inject()(cc: ControllerComponents,
                                 loggingActionBuilder: LoggingActionBuilder,
                                 statusService: StatusService,
                                 implicit val ec: ExecutionContext)
    extends PORTLAdminController(cc, loggingActionBuilder) {

  def dbHealth = Action.async {
    statusService.readWriteTest.map(
      statusResult =>
        if (statusResult.read && statusResult.write)
          Ok(Json.toJson(statusResult))
        else
          InternalServerError(Json.toJson(statusResult)))
  }

  def checkIndexes = Action.async {
    statusService.checkIndexes map {
      case true  => Ok("indexes validated")
      case false => Ok("index validation failed")
    }
  }

  def buildInfo = Action {
    Ok(AdminApiBuildInfo.toJson)
  }

}
