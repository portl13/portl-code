package com.portl.test.actors.collection
import java.nio.file.Paths
import java.util.concurrent.atomic.AtomicLong

import akka.Done
import akka.actor.ActorSystem
import akka.stream.KillSwitch
import akka.stream.scaladsl.{FileIO, Source}
import akka.testkit.{ImplicitSender, TestFSMRef, TestKitBase}
import akka.util.ByteString
import com.portl.admin.actors.collection.SongkickCollector
import com.portl.test.PortlBaseTest
import mockws.{MockWS, MockWSHelpers}
import org.scalatest.PrivateMethodTester
import play.api.inject.bind
import play.api.inject.guice.GuiceableModule
import play.api.libs.ws.WSClient
import play.api.mvc.Results.ServiceUnavailable

import scala.concurrent.Future
import scala.util.{Failure, Success}

class SongkickCollectorSpec
    extends PortlBaseTest
    with TestKitBase
    with ImplicitSender
    with MockWSHelpers
    with PrivateMethodTester {

  implicit lazy val system = ActorSystem("SongkickCollectorSpec")

  override def moduleOverrides: Seq[GuiceableModule] = {
    val ws = MockWS {
      case ("GET", "https://api.songkick.com/api/3.0/events/upcoming.gz") =>
        Action {
          println("hit mock")
          ServiceUnavailable("foo")
        }
    }

    Seq(bind[WSClient].to(ws))
  }

  "SongkickCollector" should {
    val collector = TestFSMRef(injectorObj[SongkickCollector])

    "getFeedData" should {
      val getFeedData = PrivateMethod[Future[Source[ByteString, _]]]('getFeedData)
      "fail on 503" in {
        collector.underlyingActor.invokePrivate(getFeedData(true)).transformWith {
          case Success(_) => fail("future should fail on 503, but succeeded")
          case Failure(e) => e.getMessage must startWith("503")
        }
      }
    }

    "processFeedData" should {
      val processFeedData = PrivateMethod[(KillSwitch, AtomicLong, Future[Done])]('processFeedData)
      "work for feed data" in {
        val resource = getClass.getResource(s"/songkick/upcoming-20180719.head.json.gz")
        val source = FileIO.fromPath(Paths.get(resource.getPath))
        val (_, _, f) = collector.underlyingActor.invokePrivate(processFeedData(source, 100, 1))
        f.failed.foreach(e => fail(e))
        f.map(_ => succeed)
      }
    }
  }

}
