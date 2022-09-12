package com.portl.admin.controllers
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.PORTLAdminController
import com.portl.admin.models.portlAdmin.input.CreateFileUploadConfigRequest
import com.portl.admin.services.FileUploadService
import javax.inject.Inject
import play.api.libs.json.Json
import play.api.mvc.ControllerComponents

import scala.concurrent.{ExecutionContext, Future}

class FileUploadController @Inject()(
    fileUploadService: FileUploadService,
    cc: ControllerComponents,
    loggingActionBuilder: LoggingActionBuilder,
    implicit val ec: ExecutionContext
) extends PORTLAdminController(cc, loggingActionBuilder) {
  def createFileUploadConfig = Action.async(parse.json) { request =>
    val filename = request.body.as[CreateFileUploadConfigRequest].filename
    Future(Ok(Json.toJson(fileUploadService.createFileUploadConfig(filename))))
  }
}
