package com.portl.admin.actors.aggregation
import akka.actor.{Actor, ActorLogging, ActorRef}
import com.portl.commons.models.EventSource
import com.typesafe.akka.extension.quartz.QuartzSchedulerExtension
import javax.inject.{Inject, Named}
import play.api.libs.concurrent.InjectedActorSupport

object AggregationScheduler {
  final case class QueryNextTrigger(eventSource: EventSource)
}

class AggregationScheduler @Inject()(@Named("aggregation-router") router: ActorRef)
    extends Actor
    with ActorLogging
    with InjectedActorSupport {
  import AggregationScheduler._

  val scheduler = QuartzSchedulerExtension(context.system)

  def getScheduleName(eventSource: EventSource): String = s"aggregate-${eventSource.toString.toLowerCase}"

  override def preStart(): Unit = {
    EventSource.values.foreach { eventSource =>
      val scheduleName = getScheduleName(eventSource)
      try {
        scheduler.schedule(scheduleName, router, AggregationRouter.Start(eventSource))
      } catch {
        case e: IllegalArgumentException =>
          log.warning("Failed to schedule aggregation for EventSource.{}\n{}", eventSource, e.getMessage)
      }
    }
  }

  override def receive: Receive = {
    case QueryNextTrigger(eventSource) =>
      sender() ! scheduler.nextTrigger(getScheduleName(eventSource))
  }
}
