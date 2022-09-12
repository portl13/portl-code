package com.portl.admin.controllers

import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.CRUDController
import com.portl.admin.models.portlAdmin.SeededArtist
import com.portl.admin.models.portlAdmin.bulk.ImportException
import com.portl.admin.services.SeededArtistCrudService
import javax.inject.Inject
import play.api.libs.json._
import play.api.mvc._

import scala.concurrent.{ExecutionContext, Future}

class SeededArtistsController @Inject()(cc: ControllerComponents,
                                        artistService: SeededArtistCrudService,
                                        loggingActionBuilder: LoggingActionBuilder,
                                        implicit val ec: ExecutionContext)
    extends CRUDController[SeededArtist](cc, loggingActionBuilder, artistService, ec) {
  override implicit val format: OFormat[SeededArtist] = SeededArtist.format

  override def filter(req: Request[AnyContent]): Option[JsObject] =
    req.queryString.get("name").map(_.head).map(artistService.byNameSelector)

  def bulkCreate() = Action.async(parse.multipartFormData) { request =>
    val FILE_KEY = "artistNames"

    request.body
      .file(FILE_KEY)
      .map { f =>
        artistService
          .bulkAddCSV(f.ref)
          .map(r => Ok(Json.toJson(r)))
          .recover {
            case ImportException(msg, _) => BadRequest(msg)
          }
      }
      .getOrElse {
        Future(BadRequest(s"""Missing file "$FILE_KEY""""))
      }
  }
}
