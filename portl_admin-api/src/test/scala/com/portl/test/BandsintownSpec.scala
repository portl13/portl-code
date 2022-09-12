package com.portl.test
import java.io.{File, FileInputStream, FileOutputStream}

import akka.stream.Materializer
import com.portl.admin.models.internal
import com.portl.admin.models.bandsintown.{Artist, ArtistDescription, Event}
import com.portl.admin.models.portlAdmin.bulk.ImportException
import com.portl.admin.services.TimezoneResolver
import com.portl.admin.services.integrations.BandsintownService
import com.portl.test.services.MappableEventSourceTests
import org.scalatest.concurrent.ScalaFutures
import play.api.libs.Files
import play.api.libs.json.{JsObject, Json}
import reactivemongo.api.{Cursor, ReadPreference}
import reactivemongo.play.json.compat._

class BandsintownSpec extends PortlBaseTest with MappableEventSourceTests[internal.Event] {
  override val service = injectorObj[BandsintownService]
  override implicit val materializer: Materializer = injectorObj[Materializer]
  implicit val timezoneResolver: TimezoneResolver = injectorObj[TimezoneResolver]

  "BandsintownService" should {
    "upcomingEventsSource" should {
      val futureId = "future"
      val recentId = "recent"
      val pastId = "past"

      def setup = {
        val sampleEvent = Json.parse(TestJSON.bandsintownEvent).as[Event]
        val artist = Json.parse(TestJSON.bandsintownArtist).as[Artist]
        // 	"datetime" : "2018-12-07T21:00:00",
        val dateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss"

        val events = Seq(
          sampleEvent.copy(id = futureId, datetime = futureTime.toString(dateTimeFormat)),
          sampleEvent.copy(id = recentId, datetime = recentTime.toString(dateTimeFormat)),
          sampleEvent.copy(id = pastId, datetime = pastTime.toString(dateTimeFormat)),
        )
        for {
          collection <- service.collection
          _ <- resetCollection(collection)
          _ <- service.upsertArtist(Json.toJsObject(artist))
          _ <- service.bulkUpsert(events.map(Json.toJsObject(_)))
        } yield ()
      }

      "not include events from more than a day ago" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.externalId.identifierOnSource) mustNot contain(pastId)
        }
      }

      "include events in the past day" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.externalId.identifierOnSource) must contain(recentId)
        }
      }

      "include future events" in {
        for {
          _ <- setup
          future <- collectUpcomingEvents
        } yield {
          future.map(_.externalId.identifierOnSource) must contain(futureId)
        }
      }
    }

    "bulkAddDescriptions" must {

      val someDescriptions = Seq(
        ArtistDescription("6984587", "Something to see"),
        ArtistDescription("9761233", "A band in town"),
        ArtistDescription("3459812", "The greatest show on earth"),
      )

      "create multiple entries" in {
        for {
          c <- service.collection(service.ARTIST_DESCRIPTIONS)
          _ <- resetCollection(c)
          _ <- service.bulkAddDescriptions(someDescriptions)
          allEntries <- c
            .find[JsObject, JsObject](JsObject.empty)
            .sort(Json.obj("artistId" -> 1))
            .cursor[ArtistDescription](ReadPreference.primaryPreferred)
            .collect[Seq](-1, Cursor.FailOnError())
        } yield {
          allEntries mustEqual someDescriptions.sorted(Ordering.by[ArtistDescription, String](_.artistId))
        }
      }

      "update existing entries" in {
        val existingDescriptions = someDescriptions.slice(0, 2).map { artistDescription =>
          artistDescription.copy(text = artistDescription.text.reverse)
        }
        for {
          c <- service.collection(service.ARTIST_DESCRIPTIONS)
          _ <- resetCollectionWith(c, existingDescriptions)
          _ <- service.bulkAddDescriptions(someDescriptions)
          allEntries <- c
            .find[JsObject, JsObject](JsObject.empty)
            .sort(Json.obj("artistId" -> 1))
            .cursor[ArtistDescription](ReadPreference.primaryPreferred)
            .collect[Seq](-1, Cursor.FailOnError())
        } yield {
          allEntries mustEqual someDescriptions.sorted(Ordering.by[ArtistDescription, String](_.artistId))
        }
      }
    }

    "importDescriptions" must {
      "work as expected" in {
        val distinctIdCountInInputFile = 3
        val filename = "artistDescriptions.csv"
        val filepath = s"/bandsintown/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection(service.ARTIST_DESCRIPTIONS)
          _ <- resetCollection(c)
          _ <- service.importDescriptions(tempFile)
          allEntries <- c
            .find[JsObject, JsObject](JsObject.empty)
            .sort(Json.obj("artistId" -> 1))
            .cursor[ArtistDescription](ReadPreference.primaryPreferred)
            .collect[Seq](-1, Cursor.FailOnError())
        } yield allEntries.length mustEqual distinctIdCountInInputFile
      }

      "fail if the file has no artistId header" in {
        val filename = "artistDescriptions-missingArtistIdHeader.csv"
        val filepath = s"/bandsintown/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection(service.ARTIST_DESCRIPTIONS)
          _ <- resetCollection(c)
        } yield {
          val f = service.importDescriptions(tempFile)
          ScalaFutures.whenReady(f.failed) { e =>
            e mustBe an[ImportException]
          }
        }
      }

      "fail if the file has no description header" in {
        val filename = "artistDescriptions-missingDescriptionHeader.csv"
        val filepath = s"/bandsintown/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection(service.ARTIST_DESCRIPTIONS)
          _ <- resetCollection(c)
        } yield {
          val f = service.importDescriptions(tempFile)
          ScalaFutures.whenReady(f.failed) { e =>
            e mustBe an[ImportException]
          }
        }
      }

      "not create duplicates" in {
        val distinctIdCountInInputFile = 3
        val oneOfTheEntriesInTheInputFile = ArtistDescription("6984587", "Text about the artist")
        val filename = "artistDescriptions.csv"
        val filepath = s"/bandsintown/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection(service.ARTIST_DESCRIPTIONS)
          _ <- resetCollectionWith(c, Seq(oneOfTheEntriesInTheInputFile))
          _ <- service.importDescriptions(tempFile)
          allEntries <- c
            .find[JsObject, JsObject](JsObject.empty)
            .sort(Json.obj("artistId" -> 1))
            .cursor[ArtistDescription](ReadPreference.primaryPreferred)
            .collect[Seq](-1, Cursor.FailOnError())
        } yield allEntries.length mustEqual distinctIdCountInInputFile
      }

      "ignore extraneous columns" in {
        val distinctIdCountInInputFile = 3
        val filename = "artistDescriptions-extraColumns.csv"
        val filepath = s"/bandsintown/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection(service.ARTIST_DESCRIPTIONS)
          _ <- resetCollection(c)
          _ <- service.importDescriptions(tempFile)
          allEntries <- c
            .find[JsObject, JsObject](JsObject.empty)
            .sort(Json.obj("artistId" -> 1))
            .cursor[ArtistDescription](ReadPreference.primaryPreferred)
            .collect[Seq](-1, Cursor.FailOnError())
        } yield allEntries.length mustEqual distinctIdCountInInputFile
      }
    }
  }

  "Bandsintown Event" should {
    "have a title" in {
      val event = Json.parse(TestJSON.bandsintownEvent).as[Event]
      val artist = Json.parse(TestJSON.bandsintownArtist).as[Artist]

      event.toPortl(artist).title mustNot have length 0
    }
    "use the artist image" in {
      val event = Json.parse(TestJSON.bandsintownEvent).as[Event]
      val artist = Json.parse(TestJSON.bandsintownArtist).as[Artist]

      event.toPortl(artist).imageUrl must contain(artist.image_url)
    }
    "use the artist description" in {
      val event = Json.parse(TestJSON.bandsintownEvent).as[Event]
      val artist = Json.parse(TestJSON.bandsintownArtist).as[Artist]
      val description = Json.parse(TestJSON.bandsintownArtistDescription).as[ArtistDescription]

      event.toPortl(artist, Some(description)).artist.flatMap(_.description).map(_.value) must contain(description.text)
    }
  }

}
