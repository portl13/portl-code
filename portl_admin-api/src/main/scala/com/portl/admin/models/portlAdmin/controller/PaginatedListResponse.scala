package com.portl.admin.models.portlAdmin.controller
import play.api.libs.json.{JsObject, Json, OWrites}

case class PaginatedListResponse(
    totalItems: Long,
    pageSize: Int,
    page: Int,
    pageCount: Int,
    results: List[JsObject]
)

object PaginatedListResponse {
  def apply(totalItems: Long, pageSize: Int, page: Int, results: List[JsObject]): PaginatedListResponse =
    PaginatedListResponse(totalItems, pageSize, page, Math.ceil(totalItems / pageSize).toInt, results)

  implicit val writes: OWrites[PaginatedListResponse] = Json.writes[PaginatedListResponse]
}
