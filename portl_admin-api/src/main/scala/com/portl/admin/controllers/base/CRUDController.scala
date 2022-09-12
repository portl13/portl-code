package com.portl.admin.controllers.base
import java.util.UUID

import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.models.portlAdmin.HasID
import com.portl.admin.models.portlAdmin.controller.PaginatedListResponse
import com.portl.admin.services.AdminCrudService
import com.portl.commons.services.PaginationParams
import play.api.libs.json._
import play.api.mvc.{AnyContent, ControllerComponents, Request}

import scala.concurrent.{ExecutionContext, Future}
import scala.reflect.ClassTag

abstract class CRUDController[T <: HasID[T]: ClassTag](cc: ControllerComponents,
                                                       loggingActionBuilder: LoggingActionBuilder,
                                                       crudService: AdminCrudService[T],
                                                       implicit val executionContext: ExecutionContext)
    extends PORTLAdminController(cc, loggingActionBuilder) {

  val REQUEST_SIZE_MAX = 1024 * 1024

  implicit val format: OFormat[T]

  lazy val defaultSort: Option[JsObject] = Some(Json.obj("name" -> 1))

  def listAll(page: Int, pageSize: Int) = Action.async { req =>
    for {
      totalItems <- crudService.count()
      entities <- crudService.find(filter(req), Some(PaginationParams(page, pageSize)), defaultSort)
    } yield {
      val results = entities.map(Json.toJsObject(_))
      Ok(Json.toJson(PaginatedListResponse(totalItems, pageSize, page, results)))
    }
  }

  def create() = Action.async(parse.json(maxLength = REQUEST_SIZE_MAX)) { request =>
    request.body.validate[T] match {
      case JsSuccess(entity: T, _) =>
        if (entity.id.isDefined) Future(BadRequest(Json.toJson("error" -> "do not supply id")))
        crudService.create(entity).map(Json.toJson(_)).map(Created(_))
      case JsError(e) => Future(BadRequest(Json.toJson("error" -> e.mkString)))
    }
  }

  def update(id: UUID) = Action.async(parse.json(maxLength = REQUEST_SIZE_MAX)) { request =>
    request.body.validate[T] match {
      case JsSuccess(entity: T, _) =>
        if (!entity.id.contains(id)) Future(BadRequest(Json.toJson("error" -> "id mismatch")))
        else crudService.update(entity).map(Json.toJson(_)).map(Ok(_))
      case JsError(e) => Future(BadRequest(Json.toJson("error" -> e.mkString)))
    }
  }

  def delete(id: UUID) = Action.async {
    crudService.delete(id).map(_ => NoContent)
  }

  protected def filter(req: Request[AnyContent]): Option[JsObject] = None
}
