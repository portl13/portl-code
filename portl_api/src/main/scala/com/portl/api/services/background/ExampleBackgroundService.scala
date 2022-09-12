package com.portl.api.services.background

import akka.actor.{Actor, ActorSelection, ActorSystem, PoisonPill, Props}
import akka.cluster.singleton.{
  ClusterSingletonManager,
  ClusterSingletonManagerSettings,
  ClusterSingletonProxy,
  ClusterSingletonProxySettings
}
import com.google.inject.Inject
import com.portl.api.services.EventService
import org.slf4j.LoggerFactory

import scala.language.postfixOps

/**
  * Abstract class for service that starts up a background processing actor.
  * @author Kahli Burke
  */
abstract class ExampleBackgroundService(eventService: EventService) {
  val singletonName = "exampleBackgroundService"

  // Properties for constructing the actor
  def actorProps =
    Props(
      classOf[ExampleBackgroundActor],
      eventService,
    )

  // Implement in local and clustered subclasses
  def exampleActor: ActorSelection
}

/**
  * Implements the creation of the background processor for non clustered environment.
  */
class LocalExampleBackgroundService @Inject()(
    system: ActorSystem,
    eventService: EventService
) extends ExampleBackgroundService(eventService) {
  private val localActor = system.actorOf(actorProps)
  override def exampleActor = system.actorSelection(localActor.path)
}

/**
  * Implements the creation of the background processor for clustered environment.
  */
class ClusteredExampleBackgroundService @Inject()(
    system: ActorSystem,
    eventService: EventService
) extends ExampleBackgroundService(eventService) {
  val log = LoggerFactory.getLogger(getClass)
  log.info(s"Starting cluster singleton manager for example background service")

  private val exampleBackgroundSingleton = system.actorOf(
    ClusterSingletonManager.props(
      singletonProps = actorProps,
      terminationMessage = PoisonPill,
      settings = ClusterSingletonManagerSettings(system).withSingletonName(singletonName)
    ),
    name = singletonName
  )

  // Access to the singleton is made through this proxy object
  private val exampleBackgroundProxy = system.actorOf(
    ClusterSingletonProxy.props(
      singletonManagerPath = exampleBackgroundSingleton.path.toStringWithoutAddress,
      settings = ClusterSingletonProxySettings(system).withSingletonName(singletonName)
    ),
    name = s"$singletonName-proxy"
  )

  override val exampleActor = system.actorSelection(exampleBackgroundProxy.path)

}

class ExampleBackgroundActor(eventService: EventService) extends Actor {
  import scala.concurrent.duration._
  val log = LoggerFactory.getLogger(getClass)
  object Tick

  import context.dispatcher
//  context.system.scheduler.schedule(1000 milliseconds, 1000 milliseconds, self, Tick)

  override def receive = {
    case Tick =>
      log.info("Background processor Tick!")
    case ExampleMessage(s) =>
      log.info(s"Background processor received message: $s")
  }
}

case class ExampleMessage(msg: String)
