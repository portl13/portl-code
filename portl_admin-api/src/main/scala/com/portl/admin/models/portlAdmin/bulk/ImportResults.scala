package com.portl.admin.models.portlAdmin.bulk
import play.api.libs.json.{Json, OFormat}
import reactivemongo.api.commands.{MultiBulkWriteResult, UpdateWriteResult}

case class ImportResults(receivedCount: Int, insertedCount: Int, updatedCount: Int) {
  def merge(writeResult: MultiBulkWriteResult): ImportResults = {
    ImportResults(
      receivedCount + writeResult.totalN,
      insertedCount + writeResult.n - writeResult.nModified,
      updatedCount + writeResult.nModified)
  }

  def merge(writeResult: UpdateWriteResult): ImportResults = {
    ImportResults(
      receivedCount + writeResult.n,
      insertedCount + writeResult.n - writeResult.nModified,
      updatedCount + writeResult.nModified)
  }
}

object ImportResults {
  implicit val format: OFormat[ImportResults] = Json.format[ImportResults]
  val empty = ImportResults(0, 0, 0)
}
