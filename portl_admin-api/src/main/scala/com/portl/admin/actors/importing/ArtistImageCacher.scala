package com.portl.admin.actors.importing

import java.io.File
import java.nio.file.Files
import java.util.UUID

import akka.Done
import akka.actor.{Actor, ActorLogging, FSM}
import akka.stream.scaladsl.{Keep, Sink, Source}
import akka.stream.{KillSwitch, KillSwitches, Materializer}
import akka.util.ByteString
import com.portl.admin.actors.SharedMessages
import com.portl.admin.models.portlAdmin.Artist
import com.portl.admin.services.{ArtistCrudService, FileUploadService}
import javax.inject.Inject
import play.api.libs.json.{JsObject, Json}
import play.api.libs.ws.WSClient
import reactivemongo.akkastream.cursorProducer
import reactivemongo.api.ReadPreference
import reactivemongo.api.bson.BSONRegex
import reactivemongo.play.json.compat._

import scala.concurrent.Future
import scala.concurrent.duration._
import scala.util.{Failure, Success}

object ArtistImageCacher {
  // messages
  private case object Finished
  private case object Failed

  trait Data
  case object EmptyData extends Data
  case class RunningData(ks: KillSwitch) extends Data

  sealed trait State
  case object Stopped extends State
  case object Running extends State
}

class ArtistImageCacher @Inject()(artistCrudService: ArtistCrudService,
                                  fileUploadService: FileUploadService,
                                  ws: WSClient,
                                  implicit val materializer: Materializer)
  extends Actor with FSM[ArtistImageCacher.State, ArtistImageCacher.Data] with ActorLogging {

  import ArtistImageCacher._
  import SharedMessages._
  import context._

  implicit val timeout: akka.util.Timeout = 5.seconds

  startWith(Stopped, EmptyData)

  when(Stopped) {
    case Event(Start, _) =>
      val (ks, futureDone) = cacheImages()
      futureDone.onComplete {
        case Success(_) =>
          log.info("image caching finished")
          self ! Finished
        case Failure(IntentionallyStoppedException) =>
          log.info("image caching intentionally stopped")
        case Failure(exception) =>
          log.error(exception, "image caching failed")
          self ! Failed
      }
      goto(Running) using RunningData(ks)
  }

  when(Running) {
    case Event(Stop, RunningData(ks)) =>
      ks.abort(IntentionallyStoppedException)
      goto(Stopped)
    case Event(Finished, _) =>
      goto(Stopped)
  }

  whenUnhandled {
    case Event(Stop, _) =>
      goto(Stopped)
    case Event(Failed, _) =>
      goto(Stopped)
    case Event(QueryStatus, _) =>
      stay replying currentStatus
  }

  onTransition {
    case (Stopped, x) if x != Stopped =>
      artistCrudService.count(Some(artistsSelector)).map(c =>
        log.info("caching images for {} artists with external images", c))
    case (x, Stopped) if x != Stopped =>
      artistCrudService.count(Some(artistsSelector)).map(c =>
        log.info("caching images stopped with {} remaining artists with external images", c))
  }

  val artistsSelector: JsObject = Json.obj("imageUrl" -> Json.obj("$not" -> fromRegex(BSONRegex(s"^${fileUploadService.publicBaseURL}", ""))))

  def currentStatus: JsObject = {
    val serializedData: JsObject = JsObject.empty
    Json.obj(
      "state" -> stateName.toString,
      "data" -> serializedData
    )
  }

  private def cacheImages(): (KillSwitch, Future[Done]) = {

    val futureSource = artistCrudService.collection.map(
      _.find[JsObject, JsObject](artistsSelector, None)
        .cursor[Artist](ReadPreference.secondaryPreferred)
        .documentSource()
    )

    val source = Source.fromFutureSource(futureSource)

    val (killSwitch: KillSwitch, done: Future[Done]) = source
      .viaMat(KillSwitches.single)(Keep.right)
      .mapAsync(1) { artist =>
        cacheImage(artist.id.get)
      }
      .toMat(Sink.foreach(r => log.debug(s"processAllEvents: $r")))(Keep.both)
      .run()
    (killSwitch, done)
  }


  private def fetchImage(imageUrl: String): Future[File] = {
    log.info(s"fetch image $imageUrl")
    ws.url(imageUrl).withMethod("GET").stream().flatMap { r =>
      val file = File.createTempFile("file", null)
      val out = Files.newOutputStream(file.toPath)
      r.bodyAsSource
        .runWith(Sink.foreach[ByteString] { s =>
          out.write(s.toArray)
        })
        .andThen {
          case result =>
            out.close()
            result.get
        }
        .map(_ => file)
    }
  }

  private def cacheImage(entityId: UUID): Future[Done] = {
    artistCrudService
      .getById(entityId)
      .flatMap { entity =>
        val isRemote = entity.imageUrl.nonEmpty && !fileUploadService.isPortlUrl(entity.imageUrl)

        if (isRemote) {
          val filename = entity.imageUrl.split('/').last
          for {
            image <- fetchImage(entity.imageUrl)
            localUrl <- fileUploadService.uploadFile(image, filename)
            _ <- artistCrudService.update(entity.copy(imageUrl = localUrl))
          } yield Done
        } else {
          log.debug(s"skipping CacheImage($entityId): imageUrl ${entity.imageUrl} is not remote")
          Future(Done)
        }
      }
  }
}

