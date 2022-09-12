package com.portl.admin.actors.geocoding

import akka.actor.{Actor, ActorLogging, ActorRef}
import com.portl.admin.actors.SharedMessages
import com.portl.commons.models.EventSource
import com.typesafe.akka.extension.quartz.QuartzSchedulerExtension
import javax.inject.{Inject, Named}
import play.api.libs.concurrent.InjectedActorSupport


class GeocodingScheduler @Inject()(@Named("geocoding-router") router: ActorRef)
    extends Actor
    with ActorLogging
    with InjectedActorSupport {

  import SharedMessages._

  val scheduler = QuartzSchedulerExtension(context.system)

  def getScheduleName(eventSource: EventSource): String = s"geocode-${eventSource.toString.toLowerCase}"

  override def preStart(): Unit = {
    EventSource.values.foreach { eventSource =>
      val scheduleName = getScheduleName(eventSource)
      try {
        scheduler.schedule(scheduleName, router, Start(eventSource))
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
