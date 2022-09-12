package com.portl.admin.controllers

import java.util.{NoSuchElementException, UUID}

import akka.stream.Materializer
import akka.stream.scaladsl.Source
import com.github.tototoshi.csv.CSVReader
import com.opencagedata.geocoder.{OpenCageClient, OpenCageClientParams, OpenCageResponse, parts}
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.CRUDController
import com.portl.admin.models.portlAdmin.bulk.{ImportException, ImportResults}
import javax.inject.Inject
import com.portl.admin.models.portlAdmin.controller._
import com.portl.admin.services.{ArtistCrudService, EventCrudService, VenueCrudService}
import com.portl.commons.futures.FutureHelpers._
import play.api.mvc._
import com.portl.admin.models.portlAdmin.{Artist, Event, Venue}
import com.portl.admin.services.integrations.PORTLService
import com.portl.commons.models.{Address, EventCategory, Location, StoredVenue}
import org.joda.time.{DateTime, DateTimeZone}
import org.joda.time.format.{DateTimeFormat, DateTimeFormatter}
import play.api.Configuration
import play.api.libs.Files.TemporaryFile
import play.api.libs.json._

import scala.concurrent.{ExecutionContext, Future}

class EventController @Inject()(cc: ControllerComponents,
                                portlAdminService: PORTLService,
                                eventService: EventCrudService,
                                venueService: VenueCrudService,
                                artistService: ArtistCrudService,
                                loggingActionBuilder: LoggingActionBuilder,
                                configuration: Configuration,
                                implicit val ec: ExecutionContext,
                                implicit val materializer: Materializer)
  extends CRUDController[Event](cc, loggingActionBuilder, eventService, ec) {

  override implicit val format: OFormat[Event] = Event.eventFormat

  def detail(id: UUID) = Action.async {
    for {
      eventOpt <- eventService.findById(id)
      venueOpt: Option[Venue] <- traverseOptionFlat(eventOpt) { event =>
        venueService.findById(event.venueId)
      }
      artistOpt: Option[Artist] <- traverseOptionFlat(eventOpt) { event =>
        // Event => Future[Option[Artist]]
        traverseOptionFlat(event.artistId) { artistId =>
          artistService.findById(artistId)
        }
      }
    } yield {
      eventOpt
        .map { e =>
          if (e.id.isEmpty) log.warn(s"Unexpected empty id in event detail response")
          Ok(Json.toJson(EventWithDetailsResponse(e, venueOpt, artistOpt)))
        }
        .getOrElse(NotFound)
    }
  }

  def bulkCreate() = Action.async(parse.multipartFormData(maxLength = 100 * 1024 * 1024)) { request =>
    val FILE_KEY = "eventTitles"

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

  private def bulkAddCSV(csvFile: TemporaryFile): Future[ImportResults] = {
    val expectedHeaders = Set("title", "startDateTime", "timezone", "venue.id", "venue.name", "venue.location.latitude",
      "venue.location.longitude")
    val reader = CSVReader.open(csvFile)
    reader
      .readNext()
      .collect {
        case firstLine if expectedHeaders.subsetOf(firstLine.toSet) =>
          Source(reader.toStream)
            .filter(_.nonEmpty)
            .mapAsync(1)(eventFromCSVRow(firstLine))
            .recover({
              case e: NoSuchElementException => {
                log.debug(s"bulkAddCSV ended with exception: ${e}")
                None
              }
            })
            .collect {
              case Some(a) => a
            }
            .map(normalizeName)
            .batch(1000, Seq(_))(_ :+ _)
            .mapAsync(1)(eventService.bulkUpsert)
            .runFold(ImportResults.empty)(_ merge _)
        case _ => Future.failed(ImportException(s"""Missing header(s). Required all of $expectedHeaders"""))
      }
      .getOrElse {
        Future.failed(ImportException("Empty file"))
      }
  }

  def fetchTimezone(lat: Double, lng: Double): Future[Option[parts.Timezone]] = {
    val openCageKey = configuration.get[String]("com.portl.integrations.opencage.token")
    val openCage = new OpenCageClient(openCageKey)
    val params = OpenCageClientParams(withoutAnnotations=false)
    val reverseGeocode$ = openCage.reverseGeocode(lat.toFloat, lng.toFloat, params)
    reverseGeocode$.map((response: OpenCageResponse) => {
      response.results.map(result => {
        result.annotations match {
          case Some(annotation) => annotation.timezone
          case None => None
        }
      }).head
    })
  }

  def buildArtistFromCsvData(artistName: String, artistMap: Map[String, String]): Artist = {
    val urlOpt = artistMap.get("artist.url")
    val descriptionOpt = artistMap.get("artist.description")
    val imageUrl = artistMap.get("artist.imageUrl").get

    new Artist(name=artistName, url=urlOpt, imageUrl=imageUrl, description=descriptionOpt,
      id=None, officialUrl=None, facebookUrl=None, twitterUrl=None, instagramUrl=None, spotifyUrl=None,
      youtubeUrl=None, externalId=None)
  }

  def buildVenueFromCsvData(venueName: String, venueMap: Map[String, String]): Venue = {
    val lat = venueMap.get("venue.location.latitude").get
    val lng = venueMap.get("venue.location.longitude").get

    val location = Location(latitude=lat.toDouble, longitude=lng.toDouble)

    val address = Address(
      venueMap.get("venue.address.street"),
      venueMap.get("venue.address.street"),
      venueMap.get("venue.address.city"),
      venueMap.get("venue.address.state"),
      venueMap.get("venue.address.zipCode"),
      venueMap.get("venue.address.country"),
    )

    val url = venueMap.get("venue.url")

    Venue(None, venueName, location, address, url)
  }

  private def eventFromCSVRow(headers: List[String])(row: List[String]): Future[Option[Event]] = {
    var rowData: List[(String, String)] = headers.zip(row)

    val venueNameOpt: Option[String] = rowData.find(_._1 == "venue.name").map(_._2.trim())
    val artistNameOpt: Option[String] = rowData.find(_._1 == "artist.name")map(_._2.trim())

    if (venueNameOpt.isEmpty) return Future(None)

    val venueName = venueNameOpt.get
    val artistName = artistNameOpt.getOrElse("")

    for {
      artistOpt <- artistName match {
        case "" => Future(None)
        case _ => {
          artistService.findByName(artistName)
            .flatMap({
              case Some(artist) => Future(artist)
              case None => {
                val artistMap = rowData.filter(_._1.startsWith("artist.")).toMap
                val newArtist = buildArtistFromCsvData(artistName, artistMap)
                artistService.create(newArtist)
              }
            })
            .map(artist => Some(artist))
        }
      }
      venue <- venueService.findByName(venueName).flatMap({
        case Some(venue) => Future(venue)
        case None => {
          val venueMap = rowData.filter(_._1.startsWith("venue.")).toMap
          val newVenue = buildVenueFromCsvData(venueName, venueMap)
          venueService.create(newVenue)
        }
      })
      timezoneOpt <- fetchTimezone(venue.location.latitude, venue.location.longitude)
      rowData <- {
        // Add Timezone and Venue ID
        val timezoneName = timezoneOpt match {
          case Some(timezone) => timezone.name
          case None => throw new Exception("Could not determine timezone from lat/lng provided")
        }

        rowData = rowData.map({
          case ("venue.id", _) => ("venueId", venue.id.get.toString)
          case ("timezone", _) => ("timezone", timezoneName)
          case (key, value) => (key, value)
        })

        Future(rowData)
      }
      rowData <- artistOpt match {
        // Add Artist ID if available
        case Some(artist) => {
          val withArtist = rowData.map({
            case ("artist.id", _) => ("artistId", artist.id.get.toString)
            case (key, value) => (key, value)
          })
          Future(withArtist)
        }
        case None => Future(rowData)
      }
      existingEvent <- {
        val eventName = rowData.find(_._1 == "title").get._2.trim()
        val eventStartTime = rowData.find(_._1 == "startDateTime").get._2.trim()

        val artistIdOpt = artistOpt match {
          case Some(a) => a.id
          case None => None
        }

        val timezone = timezoneOpt.get.name

        eventService.findExistingAdminEvent(eventName, eventStartTime, timezone, venue.id.get, artistIdOpt)
      }
      event <- {
        if (existingEvent.isDefined) {
          Future(existingEvent)
        } else {
          Future(eventFromCsvRowCallback(rowData))
        }
      }
    } yield event

  }

  def eventFromCsvRowCallback(allEntries: List[(String, String)]): Option[Event] = {
    val nonBlank = allEntries.filter(_._2.trim() != "")

    val entriesMap = nonBlank.toMap
    var jsObject = Json.toJsObject(entriesMap)

    val sourceValue = allEntries.find(_._1 == "source").getOrElse(("source", ""))._2
    jsObject = jsObject + ("csvSource" -> Json.toJson(sourceValue))

    val timezoneValue = allEntries.find(_._1 == "timezone").get._2
    val startDateValue = allEntries.find(_._1 == "startDateTime").getOrElse(("startDateTime", ""))._2

    val formatter: DateTimeFormatter = DateTimeFormat.forPattern("yyyy-MM-dd'T'HH:mm:ss")
    val dateTime: DateTime = formatter.withZone(DateTimeZone.forID(timezoneValue)).parseDateTime(startDateValue)
    implicit val dateTimeWriter: Writes[DateTime] = JodaWrites.jodaDateWrites("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    jsObject = jsObject + ("startDateTime" -> Json.toJson(dateTime))

    val categoryValue = allEntries.find(_._1 == "category").getOrElse(("category", ""))._2
    jsObject = jsObject + ("categories" -> Json.arr(EventCategory.getForCategoryString(categoryValue)))

    implicit val dateTimeReader: Reads[DateTime] = JodaReads.jodaDateReads("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    implicit val eventFormat: OFormat[Event] = Json.format[Event]

    val result = jsObject.validate[Event](eventFormat) match {
      case JsSuccess(a, _) => Some(a)
      case e: JsError =>
        log.warn(s"skipping invalid event with error $e")
        None
    }

    result
  }

  private def normalizeName(event: Event): Event =
    event.copy(title=event.title.trim.replaceAll("""\s+""", " "))
  // private def normalizeName[S](source: S): S =
  //   source.copy(name=artist.name.trim.replaceAll("""\s+""", " "))

  override def filter(req: Request[AnyContent]): Option[JsObject] =
    req.queryString.get("q").map(_.head).map(eventService.byNameSelector)
}
