package com.portl.admin.controllers
import java.util.UUID

import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.PORTLAdminController
import com.portl.admin.models.internal.{PORTLEntity, Venue}
import com.portl.admin.services.{MeetupPhotosFixService, TestSomeCodeService, VenueCrudService}
import com.portl.admin.services.integrations.PORTLService
import javax.inject.Inject
import play.api.libs.json.{JsValue, Json, OFormat, OWrites}
import play.api.mvc.{Action, ControllerComponents, Result}
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import com.portl.commons.models.EventSource
import com.portl.admin.models.meetup.{Event => MeetupEvent}

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

class TestSomeCodeController @Inject()(
                                      testService: TestSomeCodeService,
                                      photosFixService: MeetupPhotosFixService,
                                      venueService: VenueCrudService,
                                      portlService: PORTLService,
                                      cc: ControllerComponents,
                                      loggingActionBuilder: LoggingActionBuilder,
                                      implicit val ec: ExecutionContext
                                    ) extends PORTLAdminController(cc, loggingActionBuilder) {

    def getMockDupeVenue(): Venue = {
      // Testing for collection creating duplicate records
      implicit val format: OFormat[Venue] = Venue.venueFormat

      val jsString = """{
        "externalId": {
          "sourceType": 1,
          "identifierOnSource": "ZFr9jZAAkF"
        }
        ,
        "name": "Wow Hall"
        ,
        "location": {
          "type": "Point",
          "coordinates": [
          -123.08200073242188,
          44.06850051879883
          ]
        }
        ,
        "address": {
          "street": "291 W 8th Avenue",
          "city": "Eugene",
          "state": "OR",
          "zipCode": "97401",
          "country": "US"
        }
      }"""
      val jsObj = Json.parse(jsString)
      jsObj.as[Venue](format)
    }

    def runSomeCode: Action[JsValue] = Action.async(parse.json(maxLength = 512))(request => {
      // Testing for dedupe future Meetup events
      for {
        meetupEvent <- photosFixService.getSpecificMeetupEvent("251419054")  // No photo_url, but group_photo
        // meetupEvent <- testService.getSpecificMeetupEvent("250635094")  // No photo_url, no group_photo
        //meetupEvent <- testService.getSpecificMeetupEvent("kkrtfpyxkbqb") // Has a photo_url, no group_photo
      if meetupEvent.isDefined
        _ <- portlService.storeEvent(meetupEvent.get)
      } yield {
        Ok(Json.toJson[MeetupEvent](meetupEvent.get).toString())
      }

      Future(Ok("Completed"))
    })

    def xrunSomeCode: Action[JsValue] = Action.async(parse.json(maxLength = 512))(request => {
      // Testing for collection creating duplicate records

      // implicit val format: OFormat[Venue] = Venue.venueFormat
      // val mockVenue = getMockDupeVenue()
      // val mockVenueJs = Json.toJson[Venue](mockVenue)(format)

      for {
        mockVenueOpt <- getVenueJs(EventSource.Bandsintown, "869869b38d3dfed79af1c409ff38ea6bddb0a956")
        mockVenueOpt <- {
          mockVenueOpt match {
            case Some(mock) => log.debug(mock.toString())
            case None => log.debug("-------- VENUE SPECIFIED WAS NOT FOUND --------")
          }
          Future(mockVenueOpt)
        }
        if mockVenueOpt.isDefined
        mockVenueJs <- Future(mockVenueOpt.get)
        mockVenueJs <- {
          Future(mockVenueJs)
          //import play.api.libs.json._
          //val transformer = (__ \ 'externalId \ 'identifierOnSource).json.update({
          //  __.read[String].map(id => JsString("ThisIsAnIdWeveNeverSeen"))
          //})
          //val uniqueVenueJs = mockVenueJs.transform(transformer) match {
          //  case JsSuccess(mockVenueJs, _) => mockVenueJs
          //}
          //log.debug(uniqueVenueJs.toString())
          //Future(uniqueVenueJs)
        }
        mockVenue <- Future(mockVenueJs.as[Venue])
        resultJsValue <- portlService.storeVenue(mockVenue).map({
          case Some(venue) => {
            Ok(Json.obj("status" -> "Value returned from storeVenue()"))
          }
          case None => Ok(Json.obj("status" -> "No value from storeVenue()"))
        })(ec)
      } yield resultJsValue

      // Future(Ok(mockVenueJs))(ec)
    })

  def getVenueJs(source: EventSource, id: String): Future[Option[JsValue]] = {
    // Testing for collection creating duplicate records
    testService.getSpecificVenue(source, id).map({
      case Some(venue) => {
        implicit val writes: OWrites[Venue] = Json.writes[Venue]
        val venueJs = Json.toJson[Venue](venue)(writes)
        Some(venueJs)
      }
      case None => None
    })
  }

  def runSomeCodeX(): Action[JsValue] = Action.async(parse.json(maxLength = 512))(request => {
    // Testing for collection creating duplicate records
    getVenueJs(EventSource.Ticketmaster, "ZFr9jZAAkF").map({
      case Some(venueJs) => Ok(venueJs)
      case None => Ok(Json.obj("status" -> "No venue found"))
    })
  })

  def queryVenue: Action[JsValue] = Action.async(parse.json(maxLength = 512))(request => {
    testService.getSpecificVenue(EventSource.Ticketmaster, "ZFr9jZAAkF").map({
      case Some(venue) => {
        implicit val writes: OWrites[Venue] = Json.writes[Venue]
        val venueJs = Json.toJson[Venue](venue)(writes)
        Ok(venueJs)
      }
      case None => Ok(Json.obj("status" -> "Not Found"))
    })(ec)
  })
}
