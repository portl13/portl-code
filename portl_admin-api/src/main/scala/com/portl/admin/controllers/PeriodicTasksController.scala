package com.portl.admin.controllers
import akka.actor.ActorRef
import akka.pattern.ask
import akka.util.Timeout
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.actors.{PeriodicTaskScheduler, SharedMessages}
import com.portl.admin.controllers.base.PORTLAdminController
import javax.inject.{Inject, Named}
import play.api.mvc.ControllerComponents

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

class PeriodicTasksController @Inject()(cc: ControllerComponents,
                                        loggingActionBuilder: LoggingActionBuilder,
                                        @Named("periodic-task-scheduler") scheduler: ActorRef,
                                        @Named("event-offloader") eventOffloader: ActorRef,
                                        @Named("artist-image-cacher") artistImageCacher: ActorRef,
                                        @Named("prune-duplicate-venues") pruneDuplicateVenues: ActorRef,
                                        @Named("prune-duplicate-events") pruneDuplicateEvents: ActorRef,
                                        implicit val ec: ExecutionContext)
    extends PORTLAdminController(cc, loggingActionBuilder) {

  // TODO : Combine with CollectionController / AggregationController?

  implicit val timeout: Timeout = 10.seconds

  def getSchedule = Action.async {
    (scheduler ? PeriodicTaskScheduler.QueryNextTrigger("offload-events")).map(r => Ok(r.toString))
  }
  def getStatus = Action.async {
    (eventOffloader ? SharedMessages.QueryStatus).map(r => Ok(r.toString))
  }
  def start = Action {
    eventOffloader ! SharedMessages.Start
    Redirect(routes.PeriodicTasksController.getStatus)
  }

  def getPruneVenuesSchedule = Action.async {
    (scheduler ? PeriodicTaskScheduler.QueryNextTrigger("prune-duplicate-venues")).map(r => Ok(r.toString))
  }
  def getPruneVenuesStatus = Action.async {
    (artistImageCacher ? SharedMessages.QueryStatus).map(r => Ok(r.toString))
  }
  def startPruneVenues = Action {
    artistImageCacher ! SharedMessages.Start
    Redirect(routes.PeriodicTasksController.getPruneVenuesStatus)
  }

  def getPruneEventsSchedule = Action.async {
    (scheduler ? PeriodicTaskScheduler.QueryNextTrigger("prune-duplicate-events")).map(r => Ok(r.toString))
  }
  def getPruneEventsStatus = Action.async {
    (artistImageCacher ? SharedMessages.QueryStatus).map(r => Ok(r.toString))
  }
  def startPruneEvents = Action {
    artistImageCacher ! SharedMessages.Start
    Redirect(routes.PeriodicTasksController.getPruneEventsStatus)
  }


  def getArtistImageCacherSchedule = Action.async {
    (scheduler ? PeriodicTaskScheduler.QueryNextTrigger("cache-artist-images")).map(r => Ok(r.toString))
  }
  def getArtistImageCacherStatus = Action.async {
    (artistImageCacher ? SharedMessages.QueryStatus).map(r => Ok(r.toString))
  }
  def startArtistImageCacher = Action {
    artistImageCacher ! SharedMessages.Start
    Redirect(routes.PeriodicTasksController.getArtistImageCacherStatus)
  }
  def stopArtistImageCacher = Action {
    artistImageCacher ! SharedMessages.Stop
    Redirect(routes.PeriodicTasksController.getArtistImageCacherStatus)
  }

}
