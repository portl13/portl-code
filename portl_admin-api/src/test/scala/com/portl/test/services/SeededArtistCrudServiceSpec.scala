package com.portl.test.services
import java.io.{File, FileInputStream, FileOutputStream}

import com.portl.admin.models.portlAdmin.SeededArtist
import com.portl.admin.models.portlAdmin.bulk.ImportException
import com.portl.admin.services.SeededArtistCrudService
import com.portl.test.PortlBaseTest
import org.scalatest.concurrent.ScalaFutures
import play.api.libs.Files
import play.api.libs.json.Json

class SeededArtistCrudServiceSpec extends PortlBaseTest {
  "SeededArtistCrudService" must {
    val service = injectorObj[SeededArtistCrudService]

    "bulkAdd" must {
      val someNames = Seq("Emilio Lopez", "Austin Lally", "Jeff Creed")

      "create multiple entries" in {
        for {
          c <- service.collection
          _ <- resetCollection(c)
          _ <- service.bulkAdd(someNames)
          allArtists <- service.find(None, None, Some(Json.obj("name" -> 1)))
        } yield {
          allArtists.map(_.name) mustEqual someNames.sorted
        }
      }

      "ignore entries that already exist" in {
        for {
          c <- service.collection
          _ <- resetCollectionWith(c, someNames.slice(0, 2).map(SeededArtist(Some(service.newId), _)))
          _ <- service.bulkAdd(someNames)
          allArtists <- service.find(None, None, Some(Json.obj("name" -> 1)))
        } yield {
          allArtists.map(_.name) mustEqual someNames.sorted
        }
      }

      "not change ids of names that already exist" in {
        val existingId = service.newId
        val existingArtist = SeededArtist(Some(existingId), someNames.head)

        for {
          c <- service.collection
          _ <- resetCollectionWith(c, Seq(existingArtist))
          _ <- service.bulkAdd(someNames)
          updatedArtist <- service.findById(existingId)
        } yield {
          updatedArtist must contain(existingArtist)
        }
      }
    }

    "bulkAddCSV" must {
      "create entries for the given names" in {
        val distinctNameCountInInputFile = 6
        val filename = "artistNames.csv"
        val filepath = s"/seededArtists/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection
          _ <- resetCollection(c)
          _ <- service.bulkAddCSV(tempFile)
          allEntries <- service.find()
        } yield allEntries.length mustEqual distinctNameCountInInputFile
      }

      "fail if the file has no Artist Name header" in {
        val filename = "artistNames-wrongHeader.csv"
        val filepath = s"/seededArtists/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection
          _ <- resetCollection(c)
        } yield {
          val f = service.bulkAddCSV(tempFile)
          ScalaFutures.whenReady(f.failed) { e =>
            e mustBe an[ImportException]
          }
        }
      }

      "not create duplicates" in {
        val distinctNameCountInInputFile = 6
        val oneOfTheNamesInTheInputFile = "foo"
        val filename = "artistNames.csv"
        val filepath = s"/seededArtists/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection
          _ <- resetCollectionWith(c, Seq(SeededArtist(Some(service.newId), oneOfTheNamesInTheInputFile)))
          _ <- service.bulkAddCSV(tempFile)
          allEntries <- service.find()
        } yield allEntries.length mustEqual distinctNameCountInInputFile
      }

      "ignore extraneous columns" in {
        val distinctNameCountInInputFile = 6
        val filename = "artistNames-extraColumns.csv"
        val filepath = s"/seededArtists/$filename"

        val url = getClass.getResource(filepath)
        val file = new File(url.getPath)
        val fis = new FileInputStream(file)

        val tempFile = Files.SingletonTemporaryFileCreator.create(filename)
        val fos = new FileOutputStream(tempFile)
        fos.getChannel.transferFrom(fis.getChannel, 0, Long.MaxValue)

        for {
          c <- service.collection
          _ <- resetCollection(c)
          _ <- service.bulkAddCSV(tempFile)
          allEntries <- service.find()
        } yield allEntries.length mustEqual distinctNameCountInInputFile
      }
    }
  }
}
