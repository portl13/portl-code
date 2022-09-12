package com.portl.test

import com.portl.api.services.VenueService
import com.portl.commons.futures.FutureHelpers
import com.portl.commons.models.base.MongoObjectId
import com.portl.commons.services.PaginationParams
import org.joda.time.{DateTime, DateTimeZone}
import play.api.libs.json.{JsResultException, Json}
import reactivemongo.play.json.compat._
import squants.space.LengthConversions._

import scala.concurrent.Future

class VenueServiceSpec extends PortlBaseTest with DataGenerator {

  private val service = injectorObj[VenueService]

  "VenueService" must {
    "find venues by name with case-insensitive phrase match" in {
      val v1 = TestObjects.storedVenue().copy(name = Some("Wholesale Foods"))
      val v2 = TestObjects.storedVenue().copy(name = Some("Whole Foods"))
      val v3 = TestObjects.storedVenue().copy(name = Some("Eugene Whole Foods"))
      val v4 = TestObjects.storedVenue().copy(name = Some("Whole Foods Market"))
      val v5 = TestObjects.storedVenue().copy(name = Some("Whole Pet Foods"))
      for {
        c <- service.collection
        _ <- resetCollection(c)
        _ <- FutureHelpers.executeSequentially(Seq(v1, v2, v3, v4, v5))(service.insert)
        results <- service.search("whole foods")
      } yield results.toSet mustEqual Set(v2, v3, v4)
    }

    "exclude venues marked for deletion when searching" in {
      val now = DateTime.now
      val v1 = TestObjects.storedVenue().copy(name = Some("Whole Foods"), markedForDeletion = Some(now))
      val v2 = TestObjects.storedVenue().copy(name = Some("Whole Foods"), markedForDeletion = Some(now))
      val v3 = TestObjects.storedVenue().copy(name = Some("Whole Foods"), markedForDeletion = Some(now))
      val v4 = TestObjects.storedVenue().copy(name = Some("Whole Foods"))
      val v5 = TestObjects.storedVenue().copy(name = Some("Whole Foods"), markedForDeletion = Some(now))
      for {
        c <- service.collection
        _ <- resetCollection(c)
        _ <- FutureHelpers.executeSequentially(Seq(v1, v2, v3, v4, v5))(service.insert)
        results <- service.search("Whole Foods")
      } yield results.toSet mustEqual Set(v4)
    }

    "include venues marked for deletion when looking up by id" in {
      // DateTime is persisted as js timestamp and tzinfo is lost. When deserialized, it comes out as a UTC DateTime.
      val now = DateTime.now.withZone(DateTimeZone.UTC)
      val v1 = TestObjects.storedVenue().copy(markedForDeletion = Some(now))
      for {
        c <- service.collection
        _ <- resetCollection(c)
        _ <- service.insert(v1)
        result <- service.findById(v1.id)
      } yield result.value mustEqual v1
    }

    "searchNear" should {

      "find venues near a location" in {
        val v1 = TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene)
        val v2 = TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.portland)
        val v3 = TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.seattle)
        val v4 = TestObjects.storedVenue().copy(name = Some("whole Foods"), location = presetLocations.sanfrancisco)

        for {
          c <- service.collection
          _ <- resetCollection(c)
          _ <- FutureHelpers.executeSequentially(Seq(v3, v1, v2, v4))(service.insert)
          results <- service.searchNear("hole foo", presetLocations.eugene, maxDistance = Some(1000.miles))
        } yield results mustEqual Seq(v1, v2, v3, v4)
      }

      "not include venues outside the specified distance" in {
        val name = "Whole Foods"
        val distance = 10.miles

        val v1 = TestObjects.storedVenue().copy(name = Some(name), location = presetLocations.eugene)
        val v2 = TestObjects.storedVenue().copy(name = Some(name), location = presetLocations.portland)

        for {
          c <- service.collection
          _ <- resetCollectionWith(c, Seq(v1, v2))
          results <- service.searchNear(name, presetLocations.eugene, maxDistance = Some(distance))
        } yield {
          results must contain(v1)
          results mustNot contain(v2)
        }
      }
    }

    "handle malformed venues" should {

      "fail when looking up a malformed venue by id" in {
        val badId = MongoObjectId.generate
        // These won't deserialize as StoredVenues
        // externalId is required for deserialization, but we don't search by it
        val invalidVenues = List(
          Json.toJsObject(
            TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene, id = badId)
          ) - "externalId",
        )
        for {
          collection <- service.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(invalidVenues.map(iv => collection.insert(ordered=false).one(iv)))
        } yield {
          val f = service.findById(badId)
          f.failed.futureValue mustBe a[JsResultException]
        }
      }

      "exclude malformed venues from search results" in {
        val badId = MongoObjectId.generate
        val validVenues = List(
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
        )
        // These won't deserialize as StoredVenues
        // externalId is required for deserialization, but we don't search by it
        val invalidVenues = List(
          Json.toJsObject(
            TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene, id = badId)
          ) - "externalId",
        )

        for {
          collection <- service.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(validVenues.map(service.insert))
          _ <- Future.sequence(invalidVenues.map(iv =>collection.insert(ordered=false).one(iv)))
          searchResults <- service.search("whole foods")
        } yield {
          searchResults.map(_.id) must not contain badId
        }
      }

      "return pages smaller than expected when excluding malformed venues from search results" in {
        val badId = MongoObjectId.generate
        val validVenues = List(
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
          TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.eugene),
        )
        // These won't deserialize as StoredVenues
        // externalId is required for deserialization, but we don't search by it
        // Note these invalid venues are in a different location so they will affect the first page
        val invalidVenues = List(
          Json.toJsObject(
            TestObjects.storedVenue().copy(name = Some("Whole Foods"), location = presetLocations.portland, id = badId),
          ) - "externalId",
        )

        for {
          collection <- service.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(validVenues.map(service.insert))
          _ <- Future.sequence(invalidVenues.map(iv => collection.insert(ordered=false).one(iv)))
          searchResults <- service.searchNear(
            "whole foods",
            presetLocations.portland,
            Some(PaginationParams(0, validVenues.length)),
            Some(200.miles)
          )
        } yield {
          searchResults.length mustEqual validVenues.length - invalidVenues.length
        }
      }
    }
  }
}
