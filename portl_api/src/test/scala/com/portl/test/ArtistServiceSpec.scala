package com.portl.test

import com.portl.api.services.ArtistService
import com.portl.commons.models.base.MongoObjectId
import com.portl.commons.services.PaginationParams
import org.joda.time.{DateTime, DateTimeZone}
import play.api.libs.json.{JsObject, JsResultException, Json}
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.api.ReadConcern
import reactivemongo.play.json.collection.JSONCollection
import reactivemongo.play.json.compat._

import scala.concurrent.Future

class ArtistServiceSpec extends PortlBaseTest {

  private val artistService = injectorObj[ArtistService]
  private val reactiveMongoApi = injectorObj[ReactiveMongoApi]
  def artistsCollection: Future[JSONCollection] = reactiveMongoApi.database.map(_.collection[JSONCollection]("artists"))

  "ArtistService" must {
    "insert an artist" in {
      for {
        c <- artistsCollection
        _ <- c.delete().one(JsObject.empty)
        initialCount <- c.count(None, None, 0, None, ReadConcern.Local)
        _ <- artistService.insert(TestObjects.storedArtist())
        finalCount <- c.count(None, None, 0, None, ReadConcern.Local)
      } yield {
        finalCount mustBe (initialCount + 1)
      }
    }

    "find artists by name with case-insensitive exact match" in {
      val a1 = TestObjects.storedArtist().copy(name = "Coldplay")
      val a2 = TestObjects.storedArtist().copy(name = "Coldplay Cover Band")
      for {
        c <- artistsCollection
        _ <- resetCollection(c)
        _ <- c.insert(ordered = false).one(a1)
        _ <- c.insert(ordered = false).one(a2)
        results <- artistService.search("coldplay")
      } yield results mustEqual List(a1)
    }

    "exclude artists marked for deletion when searching" in {
      val now = DateTime.now.withZone(DateTimeZone.UTC)
      val a1 = TestObjects.storedArtist().copy(name = "Coldplay", markedForDeletion = Some(now))
      val a2 = TestObjects.storedArtist().copy(name = "Coldplay")
      for {
        c <- artistsCollection
        _ <- resetCollection(c)
        _ <- c.insert(ordered = false).one(a1)
        _ <- c.insert(ordered = false).one(a2)
        results <- artistService.search("Coldplay")
      } yield results mustEqual List(a2)
    }

    "include artists marked for deletion when looked up by id" in {
      val now = DateTime.now.withZone(DateTimeZone.UTC)
      val a1 = TestObjects.storedArtist().copy(name = "Coldplay", markedForDeletion = Some(now))
      for {
        c <- artistsCollection
        _ <- resetCollection(c)
        _ <- c.insert(ordered = false).one(a1)
        result <- artistService.findById(a1.id)
      } yield result.value mustEqual a1
    }

    "handle malformed artists" should {
      "fail when looking up a malformed artist by id" in {
        val badId = MongoObjectId.generate
        // These won't deserialize as StoredArtists
        // externalId is required for deserialization, but we don't search by it
        val invalidArtists = List(
          Json.toJsObject(
            TestObjects.storedArtist().copy(name = "Cool Band", id = badId)
          ) - "externalId",
        )
        for {
          collection <- artistService.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(invalidArtists.map(ia => collection.insert(ordered = false).one(ia)))
        } yield {
          val f = artistService.findById(badId)
          f.failed.futureValue mustBe a[JsResultException]
        }
      }

      "exclude malformed artists from search results" in {
        val badId = MongoObjectId.generate
        val validArtists = List(
          TestObjects.storedArtist().copy(name = "Cool Band"),
          TestObjects.storedArtist().copy(name = "Cool Band"),
        )
        // These won't deserialize as StoredArtists
        // externalId is required for deserialization, but we don't search by it
        val invalidArtists = List(
          Json.toJsObject(
            TestObjects.storedArtist().copy(name = "Cool Band", id = badId)
          ) - "externalId",
        )

        for {
          collection <- artistService.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(validArtists.map(artistService.insert))
          _ <- Future.sequence(invalidArtists.map(ia => collection.insert(ordered = false).one(ia)))
          searchResults <- artistService.search("cool band")
        } yield {
          searchResults.map(_.id) must not contain badId
        }
      }

      "return pages smaller than expected when excluding malformed artists from search results" in {
        val badId = MongoObjectId.generate
        val validArtists = List(
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
          TestObjects.storedArtist().copy(name = "cool band"),
        )
        // These won't deserialize as StoredArtists
        // externalId is required for deserialization, but we don't search by it
        // Note these artists use uppercase to sort alphabetically ahead of the valid ones and appear on the first page.
        val invalidArtists = List(
          Json.toJsObject(
            TestObjects
              .storedArtist()
              .copy(name = "Cool Band", id = badId),
          ) - "externalId",
        )

        for {
          collection <- artistService.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(validArtists.map(artistService.insert))
          _ <- Future.sequence(invalidArtists.map(ia => collection.insert(ordered = false).one(ia)))
          searchResults <- artistService.search("cool band", Some(PaginationParams(0, validArtists.length)))
        } yield {
          searchResults.length mustEqual validArtists.length - invalidArtists.length
        }
      }
    }
  }
}
