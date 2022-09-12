package com.portl.admin.controllers

import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.PORTLAdminController
import com.portl.admin.services.{MeetupPhotosFixService}
import javax.inject.Inject
import play.api.libs.json.{JsValue}
import play.api.mvc.{Action, ControllerComponents}
import com.portl.admin.models.meetup.{Event => MeetupEvent}

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}


class MeetupPhotosFixController @Inject()(
                                           photosFixService: MeetupPhotosFixService,
                                           cc: ControllerComponents,
                                           loggingActionBuilder: LoggingActionBuilder,
                                           implicit val ec: ExecutionContext
                                         ) extends PORTLAdminController(cc, loggingActionBuilder) {

  def addGroupPhotoToMeetupEvents: Action[JsValue] = Action.async(parse.json)(request => {
    // Testing for dedupe currently stored Meetup events
    photosFixService.updateEventsWithNoPhotoAsync()
    Future(Ok("Started"))
  })

}
