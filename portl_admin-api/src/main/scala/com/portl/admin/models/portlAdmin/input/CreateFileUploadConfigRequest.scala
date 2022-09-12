package com.portl.admin.models.portlAdmin.input
import play.api.libs.json.{Json, OFormat}

case class CreateFileUploadConfigRequest(
    filename: String
)

object CreateFileUploadConfigRequest {
  implicit val format: OFormat[CreateFileUploadConfigRequest] = Json.format[CreateFileUploadConfigRequest]
}
