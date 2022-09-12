package com.portl.admin.actors.collection
import java.util.concurrent.atomic.AtomicLong

import akka.Done
import akka.actor.{Actor, FSM}
import akka.stream.scaladsl.{Keep, Sink, Source}
import akka.stream.{KillSwitch, KillSwitches, Materializer}
import com.portl.admin.services.integrations.MeetupService
import javax.inject.Inject
import jawn.AsyncParser
import jawn.AsyncParser.ValueStream
import jawn.support.play.Parser._
import play.api.libs.json._
import play.api.libs.ws.{WSClient, WSRequest, WSResponse}

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

object MeetupFeedCollector {
  sealed trait State
  case object Stopped extends State
  case object Starting extends State
  case object Running extends State

  case class Data(killSwitch: Option[KillSwitch])

  // internal messages
  private case class StreamStarted(stream: WSResponse)
  private case object RequestFailed
}

class MeetupFeedCollector @Inject()(service: MeetupService,
                                    configuration: play.api.Configuration,
                                    wsClient: WSClient,
                                    implicit val materializer: Materializer)
    extends Actor
    with FSM[MeetupFeedCollector.State, MeetupFeedCollector.Data] {
  import com.portl.admin.actors.SharedMessages._
  import MeetupFeedCollector._
  import context.dispatcher

  import scala.concurrent.duration._

  private val apiToken = configuration.get[String]("com.portl.integrations.meetup.token")
  private val autoStart = configuration.get[Boolean]("com.portl.integrations.meetup.autoStartFeed")

  private val count = new AtomicLong(0)

  startWith(Stopped, Data(None), if (autoStart) Some(1.second) else None)

  when(Stopped) {
    case Event(Start, _) =>
      count.set(0)
      goto(Starting) using Data(None)
    case Event(StateTimeout, _) =>
      count.set(0)
      goto(Starting) using Data(None)
  }
  when(Starting) {
    case Event(StreamStarted(response), _) =>
      val (ks, futureDone) = processStream(response, insertEvents)
      futureDone.onComplete {
        case Success(_) =>
          log.warning(s"{} collection finished", service.eventSource.toString)
          self ! RequestFailed
        case Failure(IntentionallyStoppedException) =>
          log.info("{} collection intentionally stopped", service.eventSource.toString)
        case Failure(exception) =>
          log.error(exception, "{} collection failed", service.eventSource.toString)
          self ! RequestFailed
      }
      goto(Running) using Data(Some(ks))
  }
  when(Running) {
    case Event(Stop, Data(killSwitch)) =>
      killSwitch.foreach(_.abort(IntentionallyStoppedException))
      goto(Stopped)
  }

  whenUnhandled {
    case Event(QueryStatus, _) =>
      stay replying currentStatus
    case Event(RequestFailed, _) =>
      goto(Stopped) forMax 1.second
  }

  onTransition {
    case (Stopped, x) if x != Stopped =>
      service.countAllEvents.map(c =>
        log.info("{} collection started with {} existing events", service.eventSource.toString, c))
    case (x, Stopped) if x != Stopped =>
      service.countAllEvents.map(c =>
        log.info("{} collection stopped with {} existing events", service.eventSource.toString, c))
  }

  onTransition {
    case Stopped -> Starting =>
      val future = () => service.getLatestMTime.flatMap(requestFeedStream)
      tryWithFallback(10)(future)
        .onComplete {
          case Success(response) =>
            self ! StreamStarted(response)
          case Failure(exception) =>
            log.error(exception, "{} collection failed", service.eventSource.toString)
            self ! RequestFailed
        }
  }

  initialize()

  def currentStatus: JsObject = Json.obj("state" -> stateName.toString, "count" -> count.get)

  private def requestFeedStream(since: Option[Long]): Future[WSResponse] = {
    var request: WSRequest = wsClient
      .url("https://stream.meetup.com/2/open_events")
      .withRequestTimeout(Duration.Inf)
      .addHttpHeaders("Accept" -> "*/*")
      .addQueryStringParameters("key" -> apiToken)
    since.foreach(s => request = request.addQueryStringParameters("since_mtime" -> s.toString))
    log.debug(request.uri.toString)
    request.stream()
  }

  private def insertEvents(events: Seq[JsObject]): Future[Unit] = {
    // TODO : Add Kamon instrumentation
    val mtimes = events.flatMap { e =>
      (e \ "mtime").validate[Long].asOpt
    }
    val mtimeUpdate = if (mtimes.nonEmpty) service.setLatestMTime(mtimes.max).map(_ => ()) else Future(())
    service.bulkUpsert(events).flatMap(_ => mtimeUpdate)
  }

  private def processStream[T](response: WSResponse,
                               eventCallback: Seq[JsObject] => Future[T]): (KillSwitch, Future[Done]) = {
    val parser = AsyncParser[JsValue](mode = ValueStream)
    response.bodyAsSource
      .map(_.utf8String)
      .map(parser.absorb)
      .divertTo(Sink.foreach {
        case Left(e) => log.warning("error processing stream chunk: {}", e.getMessage)
        case _       =>
      }, _.isLeft)
      .collectType[Right[_, Seq[JsValue]]]
      .map(_.value.toIndexedSeq)
      .flatMapConcat(Source(_))
      .map(_.validate[JsObject])
      .divertTo(Sink.foreach {
        case JsError(e) => log.warning("Value did not parse as JsObject: {}", e.toString)
        case _          =>
      }, _.isError)
      .collectType[JsSuccess[JsObject]]
      .map(_.value)
      .alsoTo(Sink.foreach(_ => count.incrementAndGet))
      .batch(100, Seq(_))(_ :+ _)
      .viaMat(KillSwitches.single)(Keep.right)
      .mapAsync(1)(eventCallback)
      .toMat(Sink.ignore)(Keep.both)
      .run()
  }

  private def tryWithFallback[T](maxRetries: Int, delay: FiniteDuration = 1.second)(op: () => Future[T])(
      implicit ec: ExecutionContext): Future[T] = {
    import akka.pattern.after
    log.debug(s"tryWithFallback $maxRetries $delay")
    op().recoverWith {
      case _ if maxRetries > 0 => after(delay, context.system.scheduler)(tryWithFallback(maxRetries - 1, delay * 2)(op))
    }
  }
}
