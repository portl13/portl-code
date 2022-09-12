package com.portl.test

import com.portl.admin.models.internal.Venue
import com.portl.admin.services.integrations.PORTLService
import com.portl.commons
import com.portl.commons.models.{Location, StoredArtist, StoredEvent, StoredVenue}
import org.scalatest.PrivateMethodTester
import play.api.libs.json.Json

import scala.concurrent.Future

class PORTLServiceSpec extends PortlBaseTest with PrivateMethodTester {
  private val portlService = injectorObj[PORTLService]

  implicit class ConvertibleStoredVenue(storedVenue: StoredVenue) {
    def asVenue = Venue(
      storedVenue.externalId,
      storedVenue.name,
      storedVenue.location,
      storedVenue.address,
      storedVenue.url
    )
  }

  "PORTLService" should {
    "findDuplicateVenues" should {
      val findDuplicateVenues = PrivateMethod[Future[Seq[commons.models.StoredVenue]]]('findDuplicateVenues)

      "consider a venue to be a duplicate of itself" in {
        val storedVenue = TestObjects.storedVenue()
        val venue = storedVenue.asVenue
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must contain(storedVenue.id)
        }
      }
      "consider a venue with a name differing only in punctuation to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue().copy(name = Some("One Name"))
        val venue = storedVenue.asVenue.copy(name = Some("One' Name!"))
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must contain(storedVenue.id)
        }
      }
      "consider a venue with a name differing only in whitespace to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue().copy(name = Some("One Name"))
        val venue = storedVenue.asVenue.copy(name = Some("\tOne  \tName\n"))
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must contain(storedVenue.id)
        }
      }
      "consider a venue with a name differing only in casing to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue().copy(name = Some("One Name"))
        val venue = storedVenue.asVenue.copy(name = Some("one name"))
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must contain(storedVenue.id)
        }
      }
      "consider a venue with a combination of allowable name differences to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue().copy(name = Some("One Name"))
        val venue = storedVenue.asVenue.copy(name = Some("\tone'  Name!  "))
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must contain(storedVenue.id)
        }
      }
      "consider a nearby venue to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue().copy(location = PresetLocations.concentricSky)
        val venue = storedVenue.asVenue.copy(location = PresetLocations.eugenePublicLibrary)
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must contain(storedVenue.id)
        }
      }

      "not consider a distant venue to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue()
        val venue = storedVenue.asVenue.copy(location = PresetLocations.seattle)
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must not contain storedVenue.id
        }
      }
      "not consider a venue with a different name to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue()
        val venue = storedVenue.asVenue.copy(name = Some("Some different name"))
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must not contain storedVenue.id
        }
      }
      "not consider a venue with a slightly different name to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue().copy(name = Some("Some, the different name"))
        val venue = storedVenue.asVenue.copy(name = Some("Some different name"))
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must not contain storedVenue.id
        }
      }
      "not consider a venue with no name to be a duplicate" in {
        val storedVenue = TestObjects.storedVenue()
        val venue = storedVenue.asVenue.copy(name = None)
        for {
          c <- portlService.collection("venues")
          _ <- resetCollectionWith(c, Seq(storedVenue))
          duplicates <- portlService invokePrivate findDuplicateVenues(venue, true)
        } yield {
          duplicates.map(_.id) must not contain storedVenue.id
        }
      }
    }

    "update a location if the new one has higher precision" in {
      val existingLocation = Location(100.1, 20.1)
      val newLocation = Location(100.12, 20.1)
      portlService.shouldUpdateLocation(newLocation, existingLocation) mustBe true
    }
    "update a location if the new one is different" in {
      val existingLocation = Location(100.1, 20.1)
      val newLocation = Location(100.2, 20.1)
      portlService.shouldUpdateLocation(newLocation, existingLocation) mustBe true
    }
    "not update a location if the new one has lower precision" in {
      val existingLocation = Location(100.111, 20.1)
      val newLocation = Location(100.1, 20.1)
      portlService.shouldUpdateLocation(newLocation, existingLocation) mustBe false
    }
    "write a venue" in {
      val venue = TestObjects.venue()
      for {
        v1 <- portlService.storeVenue(venue)
        v2 <- portlService.storeVenue(venue)
      } yield {
        v1 mustBe defined
        v1.get mustBe a[StoredVenue]
        v2 mustBe defined
        v2.get mustBe a[StoredVenue]
        v1.get.id mustEqual v2.get.id
        println(Json.toJson(v1))
        println(Json.toJson(v2))
        succeed
      }
    }
    "update a venue" in {
      val updatedName = Some("This name was updated!")
      val venue1 = TestObjects.venue()
      val venue2 = venue1.copy(name = updatedName)
      for {
        v1 <- portlService.storeVenue(venue1)
        v2 <- portlService.storeVenue(venue2)
      } yield {
        v1 mustBe defined
        v1.get mustBe a[StoredVenue]
        v1.get.name mustNot equal(updatedName)
        v2 mustBe defined
        v2.get mustBe a[StoredVenue]
        v2.get.name must equal(updatedName)
        v1.get.id mustEqual v2.get.id
        v1.get.externalIdSet mustEqual v2.get.externalIdSet
        println(Json.toJson(v1))
        println(Json.toJson(v2))
        succeed
      }
    }
    "write an artist" in {
      val artist = TestObjects.artist()
      for {
        a1 <- portlService.storeArtist(artist)
        a2 <- portlService.storeArtist(artist)
      } yield {
        println(Json.toJson(a1))
        println(Json.toJson(a2))
        a1 mustBe defined
        a2 mustBe defined
        a1.get mustBe a[StoredArtist]
        a2.get mustBe a[StoredArtist]
        a1.get.id mustEqual a2.get.id
      }
    }
    "write an event" in {
      val event = TestObjects.event()
      for {
        o1 <- portlService.storeEvent(event)
        o2 <- portlService.storeEvent(event)
      } yield {
        o1 mustBe defined
        o2 mustBe defined
        val e1 = o1.get
        val e2 = o2.get
        println(Json.toJson(e1))
        println(Json.toJson(e2))
        e1 mustBe a[StoredEvent]
        e2 mustBe a[StoredEvent]
        e1.id mustEqual e2.id
        e1.artist mustBe defined
        e2.artist mustBe defined
        e1.artist.get.id mustEqual e2.artist.get.id
        e1.venue.id mustEqual e2.venue.id
      }
    }
  }
}
