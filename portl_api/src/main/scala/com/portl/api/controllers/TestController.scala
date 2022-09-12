package com.portl.api.controllers

import javax.inject.Inject

import akka.actor.ActorSystem
import com.portl.api.services.background.{ExampleBackgroundService, ExampleMessage}
import play.api.mvc.{AbstractController, ControllerComponents}

import scala.concurrent.ExecutionContext

class TestController @Inject()(cc: ControllerComponents,
                               actorSystem: ActorSystem,
                               exampleBackgroundService: ExampleBackgroundService,
                               implicit val ec: ExecutionContext)
    extends AbstractController(cc) {

  def sendBackgroundMessage(msg: String) = Action {
    val backgroundActor = exampleBackgroundService.exampleActor
    backgroundActor ! ExampleMessage(msg)
    Ok("Sent!").as("application/json")
  }
}
