package com.portl.admin.actors.geocoding

import akka.actor.{Actor, ActorLogging, ActorRef}
import com.opencagedata.geocoder.OpenCageClient
import com.opencagedata.geocoder.parts.LatLong
import com.portl.admin.models.internal.Venue
import com.portl.admin.models.internal.geocoding.{ForwardGeocodingResult, ReverseGeocodingResult}
import com.portl.admin.services.GeocodingResultsService
import com.portl.commons.models.Address
import play.api.Configuration
import squants.Length
import squants.space.LengthConversions._

import scala.concurrent.Future

object Geocoder {

  sealed trait Message
  case class ForwardGeocodeRequest(replyTo: ActorRef, venue: Venue) extends Message
  case class ReverseGeocodeRequest(replyTo: ActorRef, venue: Venue) extends Message

}

class Geocoder(val configuration: Configuration, val geocodingService: GeocodingResultsService)
  extends Actor with ActorLogging {
  import Geocoder._
  import context.dispatcher

  override def receive: Receive = {
    case ForwardGeocodeRequest(replyTo, venue) =>
      forwardGeocodeVenue(venue).map(replyTo ! _)
    case ReverseGeocodeRequest(replyTo, venue) =>
      reverseGeocodeVenue(venue).map(replyTo ! _)
  }

  def forwardGeocodeVenue(venue: Venue): Future[Option[ForwardGeocodingResult]] = {
    val openCageKey = configuration.get[String]("com.portl.integrations.opencage.token")
    val openCage = new OpenCageClient(openCageKey)

    val address = addressString(venue.address)
    log.info(address)

    openCage.forwardGeocode(address)
      .map { response =>
        log.info(s"$response")
        response.results
          .filter(_.geometry.isDefined)
//          .filter(_.confidence.isDefined)
//          .sortBy(_.confidence.get)
//          .reverse
          .filter(_.bounds.isDefined)
          .sortBy(r => distanceBetween(r.bounds.get.northeast, r.bounds.get.southwest))
          .map { result =>
            val radius = result.bounds.map { b =>
              distanceBetween(b.northeast, b.southwest).toUsMiles.toFloat
            }

            ForwardGeocodingResult(
              result.geometry.get.lat,
              result.geometry.get.lng,
              radius,
              result.confidence.getOrElse(0)
            )
          }
          .headOption
      }
      .recover {
        case e =>
          log.warning(s"Error response from OpenCage: ${e.getMessage}")
          None
      }
  }

  def reverseGeocodeVenue(venue: Venue): Future[Option[ReverseGeocodingResult]] = {
    val openCageKey = configuration.get[String]("com.portl.integrations.opencage.token")
    val openCage = new OpenCageClient(openCageKey)

    val lat = venue.location.latitude.toFloat
    val lng = venue.location.longitude.toFloat
    log.info(s"lat: $lat, lng: $lng")

    openCage.reverseGeocode(lat, lng)
      .map { response =>
        log.info(s"$response")
        response.results
          .filter(_.formattedAddress.isDefined)
          .filter(_.confidence.isDefined)
          .sortBy(_.confidence.get)
          .reverse
          .map { result =>
            ReverseGeocodingResult(
              result.formattedAddress.get,
              result.confidence.getOrElse(0)
            )
          }
          .headOption
      }
      .recover {
        case e =>
          log.warning(s"Error response from OpenCage: ${e.getMessage}")
          None
      }
  }

  private def addressString(address: Address): String = {
    Seq(address.street, address.street2, address.city, address.state, address.zipCode, address.country)
      .flatten
      .filter(_.nonEmpty)
      .mkString(", ")
  }

  private def distanceBetween(l1: LatLong, l2: LatLong): Length = {
    val EARTH_RADIUS_KM = 6371

    val latDistance = Math.toRadians(l1.lat - l2.lat)
    val lngDistance = Math.toRadians(l1.lng - l2.lng)
    val sinLat = Math.sin(latDistance / 2)
    val sinLng = Math.sin(lngDistance / 2)
    val a = sinLat * sinLat +
      (Math.cos(Math.toRadians(l1.lat))
        * Math.cos(Math.toRadians(l2.lat))
        * sinLng * sinLng)
    val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    (EARTH_RADIUS_KM * c).kilometers
  }

}
