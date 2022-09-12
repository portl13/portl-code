package com.portl.admin.controllers

import akka.actor.ActorRef
import akka.util.Timeout
import com.portl.admin.actions.LoggingActionBuilder
import com.portl.commons.models.EventSource
import javax.inject.{Inject, Named}
import play.api.mvc._
import akka.pattern.ask
import com.portl.admin.actors.SharedMessages._
import com.portl.admin.controllers.base.PORTLAdminController

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._

class GeocodingController @Inject()(cc: ControllerComponents,
                                      loggingActionBuilder: LoggingActionBuilder,
                                      @Named("geocoding-router") geocodingManager: ActorRef,
                                      @Named("geocoding-scheduler") geocodingScheduler: ActorRef,
                                      implicit val ec: ExecutionContext)
  extends PORTLAdminController(cc, loggingActionBuilder) {

  implicit val timeout: Timeout = 10.seconds

  def getGeocodingSchedule(eventSource: EventSource) = Action.async {
    (geocodingScheduler ? QueryNextTrigger(eventSource)).map(r => Ok(r.toString))
  }
  def getGeocodingStatus(eventSource: EventSource) = Action.async {
    (geocodingManager ? QueryStatus(eventSource)).map(r => Ok(r.toString))
  }
  def startGeocoding(eventSource: EventSource) = Action {
    geocodingManager ! Start(eventSource)
    Redirect(routes.GeocodingController.getGeocodingStatus(eventSource))
  }
  def stopGeocoding(eventSource: EventSource) = Action {
    geocodingManager ! Stop(eventSource)
    Redirect(routes.GeocodingController.getGeocodingStatus(eventSource))
  }

}
