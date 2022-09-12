package com.portl.admin.services
import akka.stream.Materializer
import com.opencagedata.geocoder.{DeserializationError, OpenCageClient}
import com.opencagedata.geocoder.parts.LatLong
import com.portl.admin.models.internal.Venue
import com.portl.admin.models.internal.geocoding.{ForwardGeocodingResult, ReverseGeocodingResult, VenueGeocodingResult}
import com.portl.commons.models.{Address, Location}
import com.portl.commons.models.base.MongoObjectId
import com.portl.commons.services.SingleCollectionService
import javax.inject.Inject
import play.api.Configuration
import play.api.libs.json.{Json, OFormat, OWrites}
import play.modules.reactivemongo.ReactiveMongoApi
import squants.Length
import squants.space.LengthConversions._

import scala.concurrent.{ExecutionContext, Future}

class GeocodingResultsService @Inject()(val configuration: Configuration,
                                 val reactiveMongoApi: ReactiveMongoApi,
                                 implicit val executionContext: ExecutionContext,
                                 implicit val materializer: Materializer)
  extends SingleCollectionService[VenueGeocodingResult] {

  override val collectionName: String = "geocodingResults"

  private def forwardGeocodeVenue(venue: Venue): Future[Option[ForwardGeocodingResult]] = {
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
        case e: DeserializationError =>
          log.warn("OpenCage forward deserialization failure: ", e)
          None
        case e =>
          log.error("OpenCage forward unexpected failure: ", e)
          None
      }
  }

  private def reverseGeocodeVenue(venue: Venue): Future[Option[ReverseGeocodingResult]] = {
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
        case e: DeserializationError =>
          log.warn("OpenCage reverse deserialization failure: ", e)
          None
        case e =>
          log.error("OpenCage reverse unexpected failure: ", e)
          None
      }
  }

  def createEmptyGeocodingResult(venue: Venue): VenueGeocodingResult =
    VenueGeocodingResult(MongoObjectId.generate, venue.externalId, None, None)

  def lookupOrCreateGeocodingResult(venue: Venue): Future[VenueGeocodingResult] = {
    findByExternalId(venue.externalId).map { maybeResult =>
      maybeResult.getOrElse(createEmptyGeocodingResult(venue))
    }
  }

  private def lookupOrGeocodeVenue(venue: Venue): Future[VenueGeocodingResult] = {
    for {
      existingResult <- findByExternalId(venue.externalId)
      result <- existingResult
        .map(Future(_))
        .getOrElse {
          for {
            forward <- forwardGeocodeVenue(venue)
            reverse <- reverseGeocodeVenue(venue)
          } yield createEmptyGeocodingResult(venue)
            .copy(forwardGeocodingResult = forward, reverseGeocodingResult = reverse)
        }
    } yield result
  }

  private def forceGeocodeVenue(venue: Venue): Future[VenueGeocodingResult] = {
    for {
      staleResult <- lookupOrCreateGeocodingResult(venue)
      reverse <- reverseGeocodeVenue(venue)
      forward <- forwardGeocodeVenue(venue)
      result = staleResult.copy(forwardGeocodingResult = forward, reverseGeocodingResult = reverse)
      _ <- upsert(result)
    } yield result
  }

  def geocodeVenue(venue: Venue): Future[VenueGeocodingResult] = {
    for {
      result <- lookupOrGeocodeVenue(venue)
      _ <- upsert(result)
    } yield result
  }

  def findByAddress(address: String): Future[List[VenueGeocodingResult]] = {
    withCollection {
      _.findList[ByAddress, VenueGeocodingResult](
        ByAddress(address)
      )
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

case class ByAddress(address: String)
object ByAddress {
  implicit val writes: OWrites[ByAddress] = (o: ByAddress) => {
    Json.obj("reverseGeocodingResult.formattedAddress" -> o.address)
  }
}
