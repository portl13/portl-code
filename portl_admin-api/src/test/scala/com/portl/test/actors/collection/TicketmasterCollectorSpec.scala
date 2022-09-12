package com.portl.test.actors.collection
import java.nio.file.Paths
import java.util.concurrent.atomic.AtomicLong

import akka.Done
import akka.actor.ActorSystem
import akka.stream.KillSwitch
import akka.stream.scaladsl.FileIO
import akka.testkit.{ImplicitSender, TestFSMRef, TestKitBase}
import com.portl.admin.actors.collection.TicketmasterCollector
import com.portl.admin.services.integrations.TicketmasterService
import com.portl.test.PortlBaseTest
import mockws.MockWSHelpers
import org.scalatest.PrivateMethodTester

import scala.concurrent.Future

class TicketmasterCollectorSpec
    extends PortlBaseTest
    with TestKitBase
    with ImplicitSender
    with MockWSHelpers
    with PrivateMethodTester {

  implicit lazy val system = ActorSystem("SongkickCollectorSpec")
  val service = injectorObj[TicketmasterService]

  "TicketmasterCollector" should {
    val collector = TestFSMRef(injectorObj[TicketmasterCollector])
    "process feed data" in {
      val processFeedData = PrivateMethod[(KillSwitch, Future[Done])]('processFeedData)

      // TODO : parse test file and count event objects instead of hard-coding
      val eventCount = 49

      for {
        collection <- service.collection
        _ <- resetCollection(collection)
        before <- service.countAllEvents
        resource = getClass.getResource(s"/ticketmaster/eventFeed-20180409-head.json.gz")
        source = FileIO.fromPath(Paths.get(resource.getPath))
        (_, futureDone) = collector.underlyingActor.invokePrivate(processFeedData(source, new AtomicLong(0), 100, 1))
        _ <- futureDone
        after <- service.countAllEvents
      } yield {
        after must equal(before + eventCount)
      }
    }
  }
}
