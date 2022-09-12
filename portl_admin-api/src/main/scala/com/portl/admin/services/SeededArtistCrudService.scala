package com.portl.admin.services
import akka.stream.Materializer
import akka.stream.scaladsl.Source
import com.github.tototoshi.csv.CSVReader
import com.portl.admin.models.portlAdmin.SeededArtist
import com.portl.admin.models.portlAdmin.bulk.{ImportException, ImportResults}
import javax.inject.Inject
import play.api.libs.Files.TemporaryFile
import play.api.libs.json._
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.api.commands.MultiBulkWriteResult
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

class SeededArtistCrudService @Inject()(
    implicit val executionContext: ExecutionContext,
    implicit val materializer: Materializer,
    val reactiveMongoApi: ReactiveMongoApi
) extends AdminCrudService[SeededArtist] {
  val collectionName = "seededArtists"
  override implicit val format: OFormat[SeededArtist] = SeededArtist.format

  def byNameSelector(name: String): JsObject =
    Json.obj("$text" -> Json.obj("$search" -> name))

  def bulkAdd(names: Seq[String]): Future[MultiBulkWriteResult] = {
    val artists = names.map(SeededArtist(Some(newId), _))
    collection.flatMap(_.insert(ordered = false).many(artists))
  }

  def bulkAddCSV(csvFile: TemporaryFile): Future[ImportResults] = {
    val NAME_HEADER = "Artist Name"

    val reader = CSVReader.open(csvFile)
    reader
      .readNext()
      .collect {
        case headers if headers.contains(NAME_HEADER) =>
          val nameIndex = headers.indexOf(NAME_HEADER)
          Source(reader.toStream)
            .map(_(nameIndex))
            .map(normalizeArtistName)
            .filter(_.nonEmpty)
            .batch(1000, Seq(_))(_ :+ _)
            .mapAsync(1)(bulkAdd)
            .runFold(ImportResults.empty)(_ merge _)
        case _ => Future.failed(ImportException(s"""Missing header "$NAME_HEADER""""))
      }
      .getOrElse {
        Future.failed(ImportException("Empty file"))
      }
  }

  private def normalizeArtistName(name: String): String =
    name.trim.replaceAll("""\s+""", " ")
}
