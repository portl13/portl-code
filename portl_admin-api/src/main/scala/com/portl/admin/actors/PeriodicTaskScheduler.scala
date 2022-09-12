package com.portl.admin.actors
import akka.actor.{Actor, ActorLogging, ActorRef}
import com.typesafe.akka.extension.quartz.QuartzSchedulerExtension
import javax.inject.{Inject, Named}
import play.api.libs.concurrent.InjectedActorSupport

object PeriodicTaskScheduler {
  final case class QueryNextTrigger(scheduleName: String)
}

class PeriodicTaskScheduler @Inject()(
                                       @Named("event-offloader") eventOffloader: ActorRef,
                                       @Named("artist-image-cacher") artistImageCacher: ActorRef,
                                       @Named("prune-duplicate-venues") pruneDuplicateVenues: ActorRef,
                                       @Named("prune-duplicate-events") pruneDuplicateEvents: ActorRef,
                                     )
  extends Actor with ActorLogging with InjectedActorSupport {

  import PeriodicTaskScheduler._

  val scheduler = QuartzSchedulerExtension(context.system)
  val eventOffloaderScheduleName = "offload-events"
  val artistImageCacherSchedulerName = "cache-artist-images"
  val pruneDuplicateVenuesName = "prune-duplicate-venues"
  val pruneDuplicateEventsName = "prune-duplicate-events"

  override def preStart(): Unit = {
    // TODO : Does it make sense to combine this with AggregationScheduler and CollectionScheduler?
    try {
      scheduler.schedule(eventOffloaderScheduleName, eventOffloader, SharedMessages.Start)
    } catch {
      case e: IllegalArgumentException =>
        log.warning("Failed to schedule event offloading.\n{}", e.getMessage)
    }

    try {
      scheduler.schedule(artistImageCacherSchedulerName, artistImageCacher, SharedMessages.Start)
    } catch {
      case e: IllegalArgumentException =>
        log.warning("Failed to schedule image caching.\n{}", e.getMessage)
    }

    try {
      scheduler.schedule(pruneDuplicateVenuesName, pruneDuplicateVenues, SharedMessages.Start)
    } catch {
      case e: IllegalArgumentException =>
        log.warning("Failed to schedule Venue deduplication.\n{}", e.getMessage)
    }

    try {
      scheduler.schedule(pruneDuplicateEventsName, pruneDuplicateEvents, SharedMessages.Start)
    } catch {
      case e: IllegalArgumentException =>
        log.warning("Failed to schedule Event deduplication.\n{}", e.getMessage)
    }
  }

  override def receive: Receive = {
    case QueryNextTrigger(scheduleName) =>
      sender() ! scheduler.nextTrigger(scheduleName)
  }
}
