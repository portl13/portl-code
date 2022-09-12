package com.portl.admin.controllers

import akka.actor.ActorRef
import akka.pattern.ask
import akka.util.Timeout
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.actors.collection.{CollectionRouter, CollectionScheduler}
import com.portl.admin.controllers.base.PORTLAdminController
import com.portl.commons.models.EventSource
import javax.inject.{Inject, Named}
import play.api.mvc._

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

class CollectionController @Inject()(cc: ControllerComponents,
                                     loggingActionBuilder: LoggingActionBuilder,
                                     @Named("collection-router") collectionManager: ActorRef,
                                     @Named("collection-scheduler") collectionScheduler: ActorRef,
                                     implicit val ec: ExecutionContext)
    extends PORTLAdminController(cc, loggingActionBuilder) {

  // TODO : CollectionController, CollectionScheduler, CollectionRouter etc are very
  // similar to AggregationController et. al. Factor out common behavior.

  implicit val timeout: Timeout = 10.seconds

  def getCollectionSchedule(eventSource: EventSource) = Action.async {
    (collectionScheduler ? CollectionScheduler.QueryNextTrigger(eventSource)).map(r => Ok(r.toString))
  }
  def getCollectionStatus(eventSource: EventSource) = Action.async {
    (collectionManager ? CollectionRouter.QueryStatus(eventSource)).map(r => Ok(r.toString))
  }
  def startCollection(eventSource: EventSource) = Action {
    collectionManager ! CollectionRouter.Start(eventSource)
    Redirect(routes.CollectionController.getCollectionStatus(eventSource))
  }
  def stopCollection(eventSource: EventSource) = Action {
    collectionManager ! CollectionRouter.Stop(eventSource)
    Redirect(routes.CollectionController.getCollectionStatus(eventSource))
  }

}
