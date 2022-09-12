package com.portl.admin.controllers
import akka.actor.ActorRef
import akka.util.Timeout
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.actors.aggregation.{AggregationRouter, AggregationScheduler}
import com.portl.commons.models.EventSource
import javax.inject.{Inject, Named}
import play.api.mvc._
import akka.pattern.ask
import com.portl.admin.controllers.base.PORTLAdminController

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

class AggregationController @Inject()(cc: ControllerComponents,
                                      loggingActionBuilder: LoggingActionBuilder,
                                      @Named("aggregation-router") aggregationManager: ActorRef,
                                      @Named("aggregation-scheduler") aggregationScheduler: ActorRef,
                                      implicit val ec: ExecutionContext)
    extends PORTLAdminController(cc, loggingActionBuilder) {

  implicit val timeout: Timeout = 10.seconds

  def getAggregationSchedule(eventSource: EventSource) = Action.async {
    (aggregationScheduler ? AggregationScheduler.QueryNextTrigger(eventSource)).map(r => Ok(r.toString))
  }
  def getAggregationStatus(eventSource: EventSource) = Action.async {
    (aggregationManager ? AggregationRouter.QueryStatus(eventSource)).map(r => Ok(r.toString))
  }
  def startAggregation(eventSource: EventSource) = Action {
    aggregationManager ! AggregationRouter.Start(eventSource)
    Redirect(routes.AggregationController.getAggregationStatus(eventSource))
  }
  def stopAggregation(eventSource: EventSource) = Action {
    aggregationManager ! AggregationRouter.Stop(eventSource)
    Redirect(routes.AggregationController.getAggregationStatus(eventSource))
  }

}
