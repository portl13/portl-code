package com.portl.admin.models.portlAdmin

import play.api.libs.json.{Json, OFormat}

case class FileUploadConfig(
    // the URL to which the client should upload the file
    uploadURL: String,
    // the URL at which the file will be available to the public after upload
    publicURL: String
)

object FileUploadConfig {
  implicit val format: OFormat[FileUploadConfig] = Json.format[FileUploadConfig]
}
