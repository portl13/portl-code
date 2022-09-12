package com.portl.test

import akka.Done
import com.portl.commons
import com.portl.commons.models.{StoredArtist, StoredEvent}
import com.portl.api.services.EventService
import com.portl.commons.models.base.MongoObjectId
import com.portl.commons.services.PaginationParams
import org.joda.time.DateTime
import org.scalatest
import play.api.libs.json.{JsResultException, Json}
import reactivemongo.play.json.compat._
import squants.space.LengthConversions._

import scala.concurrent.Future

class EventServiceSpec extends PortlBaseTest with DataGenerator {
  private val service = injectorObj[EventService]

  def testQuery(validEvents: Seq[commons.models.StoredEvent],
                invalidEvents: Seq[commons.models.StoredEvent],
                queryFn: () => Future[Seq[commons.models.StoredEvent]]): Future[scalatest.Assertion] = {
    for {
      collection <- service.collection
      _ <- resetCollection(collection)
      _ <- Future.sequence((validEvents ++ invalidEvents).map(service.insert))
      events <- queryFn()
    } yield {
      events must have length validEvents.length
      events.map(_.id) must contain theSameElementsAs validEvents.map(_.id)
    }
  }

  "EventService" should {
    val now = DateTime.now
    val oldEvents = Seq(
      createEventAt(presetLocations.eugene, now.minusWeeks(4)),
      createEventAt(presetLocations.eugene, now.minusWeeks(5)),
      createEventAt(presetLocations.eugene, now.minusWeeks(6)),
    )
    val newEvents = Seq(
      createEventAt(presetLocations.eugene, now.minusWeeks(1)),
      createEventAt(presetLocations.eugene, now),
      createEventAt(presetLocations.eugene, now.plusWeeks(1)),
    )
    val allEvents = oldEvents ++ newEvents

    def setup: Future[Done] = {
      for {
        collection <- service.collection(service.EVENTS)
        archive <- service.collection(service.HISTORICAL_EVENTS)
        _ <- resetCollectionWith(collection, newEvents)
        _ <- resetCollectionWith(archive, oldEvents)
      } yield Done
    }

    "findByIds" must {
      "include historical events" in setup.flatMap { _ =>
        for {
          foundEvents <- service.findByIds(allEvents.map(_.id))
        } yield foundEvents.map(_.id) must contain theSameElementsAs allEvents.map(_.id)
      }
    }

    "findById" must {
      "include historical events" in setup.flatMap { _ =>
        for {
          foundEvent <- service.findById(oldEvents.map(_.id).head)
        } yield foundEvent.value.id mustEqual oldEvents.head.id
      }

      "include new events" in setup.flatMap { _ =>
        for {
          foundEvent <- service.findById(newEvents.map(_.id).head)
        } yield foundEvent.value.id mustEqual newEvents.head.id
      }
    }

    "Return events with the given ids" in {
      val now = DateTime.now
      val validEvents = List(
        createEventAt(presetLocations.eugene, now.plusDays(1)),
        createEventAt(presetLocations.eugene, now.plusDays(3))
      )
      val invalidEvents = List(
        createEventAt(presetLocations.eugene, now.minusYears(1)),
        createEventAt(presetLocations.eugene, now.minusDays(1)),
        createEventAt(presetLocations.eugene, now),
        createEventAt(presetLocations.eugene, now.plusDays(4)),
        createEventAt(presetLocations.eugene, now.plusYears(1)),
        createEventAt(presetLocations.eugene, now.plusYears(10))
      )
      val queryFn = () =>
        service.findListSortedPaginated(service.queryByObjectIds(validEvents.map(_.id)), page = 0, itemsPerPage = 10)

      testQuery(validEvents, invalidEvents, queryFn)
    }

    "Find all events when no start time is specified" in {
      val now = DateTime.now
      val validEvents = List(
        createEventAt(presetLocations.eugene, now.minusYears(1)),
        createEventAt(presetLocations.eugene, now.minusDays(1)),
        createEventAt(presetLocations.eugene, now),
        createEventAt(presetLocations.eugene, now.plusDays(1)),
        createEventAt(presetLocations.eugene, now.plusDays(3)),
        createEventAt(presetLocations.eugene, now.plusYears(1)),
        createEventAt(presetLocations.eugene, now.plusYears(10))
      )
      val queryFn = () =>
        service
          .findPaginatedIdsNear(
            presetLocations.eugene,
            PaginationParams(0, 100),
            maxDistance = Some(150.miles)
          )
          .flatMap { aggregationResult =>
            service.findListSorted(service.queryByObjectIds(aggregationResult.ids))
        }
      testQuery(validEvents, Seq(), queryFn)
    }

    "Find all future events when start time is specified" in {
      val now = DateTime.now
      val validEvents = List(
        createEventAt(presetLocations.eugene, now.plusDays(1)),
        createEventAt(presetLocations.eugene, now.plusDays(3)),
        createEventAt(presetLocations.eugene, now.plusYears(1)),
        createEventAt(presetLocations.eugene, now.plusYears(10))
      )
      val invalidEvents = List(
        createEventAt(presetLocations.eugene, now.minusYears(1)),
        createEventAt(presetLocations.eugene, now.minusDays(1)),
        createEventAt(presetLocations.eugene, now)
      )
      val queryFn = () =>
        service
          .findPaginatedIdsNear(
            presetLocations.eugene,
            PaginationParams(0, 100),
            maxDistance = Some(150.miles),
            startingAfter = Some(now)
          )
          .flatMap { aggregationResult =>
            service.findListSorted(service.queryByObjectIds(aggregationResult.ids))
        }
      testQuery(validEvents, invalidEvents, queryFn)
    }

    "Find events starting within the specified duration" in {
      val now = DateTime.now
      val validEvents = List(
        createEventAt(presetLocations.eugene, now.plusDays(1)),
        createEventAt(presetLocations.eugene, now.plusDays(3))
      )
      val invalidEvents = List(
        createEventAt(presetLocations.eugene, now.minusYears(1)),
        createEventAt(presetLocations.eugene, now.minusDays(1)),
        createEventAt(presetLocations.eugene, now),
        createEventAt(presetLocations.eugene, now.plusDays(4)),
        createEventAt(presetLocations.eugene, now.plusYears(1)),
        createEventAt(presetLocations.eugene, now.plusYears(10))
      )
      val queryFn = () =>
        service
          .findPaginatedIdsNear(
            presetLocations.eugene,
            PaginationParams(0, 100),
            maxDistance = Some(150.miles),
            startingAfter = Some(now),
            startingWithinDays = Some(4)
          )
          .flatMap { aggregationResult =>
            service.findListSorted(service.queryByObjectIds(aggregationResult.ids))
        }
      testQuery(validEvents, invalidEvents, queryFn)
    }

    "Find events inside the given radius" in {
      val theFuture = DateTime.now.plusDays(1)
      val validEvents = List(
        createEventAt(presetLocations.eugene, theFuture),
        createEventAt(presetLocations.eugene, theFuture),
        createEventAt(presetLocations.eugene, theFuture),
        createEventAt(presetLocations.eugene, theFuture),
        createEventAt(presetLocations.portland, theFuture),
        createEventAt(presetLocations.portland, theFuture)
      )
      val invalidEvents = List(
        createEventAt(presetLocations.seattle, theFuture),
        createEventAt(presetLocations.sanfrancisco, theFuture),
        createEventAt(presetLocations.sanfrancisco, theFuture)
      )
      val queryFn = () =>
        service
          .findPaginatedIdsNear(
            presetLocations.eugene,
            PaginationParams(0, 100),
            maxDistance = Some(150.miles)
          )
          .flatMap { aggregationResult =>
            service.findListSorted(service.queryByObjectIds(aggregationResult.ids))
        }
      testQuery(validEvents, invalidEvents, queryFn)
    }

    "Sort events by start date" in {
      val d1 = DateTime.now.plusDays(1)
      val d2 = DateTime.now.plusDays(2)
      val d3 = DateTime.now.plusDays(3)

      val events = List(
        createEventAt(presetLocations.sanfrancisco, d2),
        createEventAt(presetLocations.eugene, d2),
        createEventAt(presetLocations.portland, d3),
        createEventAt(presetLocations.sanfrancisco, d3),
        createEventAt(presetLocations.eugene, d3),
        createEventAt(presetLocations.seattle, d1),
        createEventAt(presetLocations.portland, d1),
        createEventAt(presetLocations.eugene, d1),
        createEventAt(presetLocations.sanfrancisco, d1),
        createEventAt(presetLocations.portland, d2),
        createEventAt(presetLocations.sanfrancisco, d1),
        createEventAt(presetLocations.seattle, d3),
        createEventAt(presetLocations.seattle, d2)
      )

      def sort(e1: StoredEvent, e2: StoredEvent): Boolean =
        e1.startDateTime.isBefore(e2.startDateTime)

      for {
        dbName <- service.databaseName
        _ <- resetCollection(dbName, service.collectionName)
        _ <- Future.sequence(events.map(service.insert))
        aggregationResult <- service
          .findPaginatedIdsNear(
            presetLocations.eugene,
            PaginationParams(0, 100),
            maxDistance = Some(1000.miles)
          )
        q = service.queryByObjectIds(aggregationResult.ids)
        found <- service.findListSorted(q, service.sortByLocalStartDate)
        sorted = found.sortWith(sort)
      } yield {
        println(sorted.map(e => (e.localStartDate, e.computedDistance)))
        found must have length events.length
        found.map(_.id) must contain theSameElementsAs events.map(_.id)
        found mustEqual sorted
      }
    }

    "Exclude events marked for deletion when searching" in {
      val now = DateTime.now
      val validEvents = List(
        createEventAt(presetLocations.eugene, now.plusDays(1)),
        createEventAt(presetLocations.eugene, now.plusDays(3))
      )
      val deletedEvents = List(
        createEventAt(presetLocations.eugene, now.minusYears(1)),
        createEventAt(presetLocations.eugene, now.minusDays(1)),
        createEventAt(presetLocations.eugene, now),
        createEventAt(presetLocations.eugene, now.plusDays(4)),
        createEventAt(presetLocations.eugene, now.plusYears(1)),
        createEventAt(presetLocations.eugene, now.plusYears(10))
      ).map(_.copy(markedForDeletion = Some(now)))

      val queryFn = () =>
        service
          .findPaginatedIdsNear(
            presetLocations.eugene,
            PaginationParams(0, 100),
            maxDistance = Some(150.miles)
          )
          .flatMap { aggregationResult =>
            service.findListSorted(service.queryByObjectIds(aggregationResult.ids))
        }
      testQuery(validEvents, deletedEvents, queryFn)
    }

    "Include events marked for deletion when queried by id" in {
      val now = DateTime.now
      val validEvents = List(
        createEventAt(presetLocations.eugene, now.plusDays(1)),
        createEventAt(presetLocations.eugene, now.plusDays(3))
      )
      val deletedEvents = List(
        createEventAt(presetLocations.eugene, now.minusYears(1)),
        createEventAt(presetLocations.eugene, now.minusDays(1)),
        createEventAt(presetLocations.eugene, now),
        createEventAt(presetLocations.eugene, now.plusDays(4)),
        createEventAt(presetLocations.eugene, now.plusYears(1)),
        createEventAt(presetLocations.eugene, now.plusYears(10))
      ).map(_.copy(markedForDeletion = Some(now)))
      val events = validEvents ++ deletedEvents
      val queryFn =
        () => service.findListSortedPaginated(service.queryByObjectIds(events.map(_.id)), page = 0, itemsPerPage = 10)

      testQuery(events, List(), queryFn)
    }

    "handle malformed events" should {

      "fail when looking up a malformed event by id" in {
        val badId = MongoObjectId.generate
        val now = DateTime.now
        // These won't deserialize as StoredEvents
        // externalId is required for deserialization, but we don't search by it
        val invalidEvents = List(
          Json.toJsObject(
            createEventAt(presetLocations.eugene, now.plusDays(1)).copy(id = badId)
          ) - "externalId",
        )
        for {
          collection <- service.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(invalidEvents.map(ie => collection.insert(ordered = false).one(ie)))
        } yield {
          val futureEvent = service.findById(badId)
          futureEvent.failed.futureValue mustBe a[JsResultException]
        }
      }

      "exclude malformed events from search results" in {
        val badId = MongoObjectId.generate
        val now = DateTime.now
        val validEvents = List(
          createEventAt(presetLocations.eugene, now.plusDays(1)),
          createEventAt(presetLocations.eugene, now.plusDays(3))
        )
        // These won't deserialize as StoredEvents
        // externalId is required for deserialization, but we don't search by it
        val invalidEvents = List(
          Json.toJsObject(
            createEventAt(presetLocations.eugene, now.plusDays(1)).copy(id = badId)
          ) - "externalId",
        )

        for {
          collection <- service.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(validEvents.map(service.insert))
          _ <- Future.sequence(invalidEvents.map(ie => collection.insert(ordered = false).one(ie)))
          searchResults <- service
            .findPaginatedIdsNear(
              presetLocations.eugene,
              PaginationParams(0, 100),
              maxDistance = Some(150.miles)
            )
            .flatMap { aggregationResult =>
              service.findListSorted(service.queryByObjectIds(aggregationResult.ids))
            }
        } yield {
          searchResults.map(_.id) must not contain badId
        }
      }

      "return pages smaller than expected when excluding malformed events from search results" in {
        val badId = MongoObjectId.generate
        val now = DateTime.now
        val validEvents = List(
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(2)),
          createEventAt(presetLocations.eugene, now.plusDays(3))
        )
        // These won't deserialize as StoredEvents
        // externalId is required for deserialization, but we don't search by it
        // Note these invalid events are set to start before the valid ones so they will affect the first page
        val invalidEvents = List(
          Json.toJsObject(
            createEventAt(presetLocations.eugene, now.plusDays(1)).copy(id = badId)
          ) - "externalId",
        )

        for {
          collection <- service.collection
          _ <- resetCollection(collection)
          _ <- Future.sequence(validEvents.map(service.insert))
          _ <- Future.sequence(invalidEvents.map(ie => collection.insert(ordered = false).one(ie)))
          searchResults <- service
            .findPaginatedIdsNear(
              presetLocations.eugene,
              PaginationParams(0, validEvents.length),
              maxDistance = Some(150.miles)
            )
            .flatMap { aggregationResult =>
              service.findListSorted(service.queryByObjectIds(aggregationResult.ids))
            }
        } yield {
          searchResults.length mustEqual validEvents.length - invalidEvents.length
        }
      }
    }
  }

  "Exclude events marked for deletion when searching by venue" in {
    val now = DateTime.now
    // Give them all the same venue
    val venue = createEventAt(presetLocations.eugene, now).venue

    val validEvents = List(
      createEventAt(presetLocations.eugene, now.plusDays(1)),
      createEventAt(presetLocations.eugene, now.plusDays(3))
    ).map(_.copy(venue = venue))
    val deletedEvents = List(
      createEventAt(presetLocations.eugene, now.minusYears(1)),
      createEventAt(presetLocations.eugene, now.minusDays(1)),
      createEventAt(presetLocations.eugene, now),
      createEventAt(presetLocations.eugene, now.plusDays(4)),
      createEventAt(presetLocations.eugene, now.plusYears(1)),
      createEventAt(presetLocations.eugene, now.plusYears(10))
    ).map(_.copy(markedForDeletion = Some(now), venue = venue))

    val queryFn = () => service.findByVenue(venue)
    testQuery(validEvents, deletedEvents, queryFn)
  }

  "Exclude events marked for deletion when searching by artist" in {
    val now = DateTime.now
    // Give them all the same artist
    val artistSourceId = randomIdentifier
    val artist = StoredArtist(
      MongoObjectId.generate,
      artistSourceId,
      Set(artistSourceId),
      "Someone",
      None,
      "https://some.image.com/foo",
      None,
      None
    )

    val validEvents = List(
      createEventAt(presetLocations.eugene, now.plusDays(1)),
      createEventAt(presetLocations.eugene, now.plusDays(3))
    ).map(_.copy(artist = Some(artist)))
    val deletedEvents = List(
      createEventAt(presetLocations.eugene, now.minusYears(1)),
      createEventAt(presetLocations.eugene, now.minusDays(1)),
      createEventAt(presetLocations.eugene, now),
      createEventAt(presetLocations.eugene, now.plusDays(4)),
      createEventAt(presetLocations.eugene, now.plusYears(1)),
      createEventAt(presetLocations.eugene, now.plusYears(10))
    ).map(_.copy(markedForDeletion = Some(now), artist = Some(artist)))

    val queryFn = () => service.findByArtist(artist)
    testQuery(validEvents, deletedEvents, queryFn)
  }
}
