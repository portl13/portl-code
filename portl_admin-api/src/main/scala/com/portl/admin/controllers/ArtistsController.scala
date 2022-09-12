package com.portl.admin.controllers

import akka.stream.Materializer
import akka.stream.scaladsl.Source
import com.github.tototoshi.csv.CSVReader
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.CRUDController
import com.portl.admin.models.portlAdmin.Artist
import com.portl.admin.models.portlAdmin.bulk.{ImportException, ImportResults}
import com.portl.admin.services.ArtistCrudService
import javax.inject.Inject
import play.api.libs.Files.TemporaryFile
import play.api.libs.json.{JsError, JsObject, JsSuccess, Json, OFormat}
import play.api.mvc._

import scala.concurrent.{ExecutionContext, Future}

class ArtistsController @Inject()(cc: ControllerComponents,
                                  artistService: ArtistCrudService,
                                  loggingActionBuilder: LoggingActionBuilder,
                                  implicit val ec: ExecutionContext,
                                  implicit val materializer: Materializer)
    extends CRUDController[Artist](cc, loggingActionBuilder, artistService, ec) {
  override implicit val format: OFormat[Artist] = Artist.artistFormat

  def bulkCreate() = Action.async(parse.multipartFormData(maxLength = 100 * 1024 * 1024)) { request =>
    val FILE_KEY = "file"

    request.body
      .file(FILE_KEY)
      .map { f =>
        bulkAddCSV(f.ref)
          .map(r => Ok(Json.toJson(r)))
          .recover {
            case ImportException(msg, _) => BadRequest(msg)
          }
      }
      .getOrElse {
        Future(BadRequest(s"""Missing file "$FILE_KEY""""))
      }
  }

  private def artistFromCSVRow(headers: List[String])(row: List[String]): Option[Artist] = {
    // treat empty entries as None, except for imageUrl
    val entries = headers.zip(row).filter(_._2.nonEmpty)
    val imageUrl = entries.find(_._1 == "imageUrl").getOrElse(("imageUrl", ""))
    val allEntries = entries.filter(_._1 != "imageUrl") :+ imageUrl
    Json.toJsObject(allEntries.toMap).validate[Artist] match {
      case JsSuccess(a, _) => Some(a)
      case e: JsError =>
        log.warn(s"skipping invalid artist $allEntries with error $e")
        None
    }
  }

  private def bulkAddCSV(csvFile: TemporaryFile): Future[ImportResults] = {
    val expectedHeaders = Set("id", "name")
    val reader = CSVReader.open(csvFile)
    reader
      .readNext()
      .collect {
        case headers if expectedHeaders.subsetOf(headers.toSet) =>
          Source(reader.toStream)
            .filter(_.nonEmpty)
            .map(artistFromCSVRow(headers))
            .collect {
              case Some(a) => a
            }
            .map(normalizeArtistName)
            .batch(1000, Seq(_))(_ :+ _)
            .mapAsync(1)(artistService.bulkUpsert)
            .runFold(ImportResults.empty)(_ merge _)
        case _ => Future.failed(ImportException(s"""Missing header(s). Required all of $expectedHeaders"""))
      }
      .getOrElse {
        Future.failed(ImportException("Empty file"))
      }
  }

  private def normalizeArtistName(artist: Artist): Artist =
    artist.copy(name=artist.name.trim.replaceAll("""\s+""", " "))

  override def filter(req: Request[AnyContent]): Option[JsObject] =
    req.queryString.get("q").map(_.head).map(artistService.byNameSelector)
}
