package com.portl.admin.actors.collection

import akka.actor.{Actor, ActorRef}
import com.portl.admin.actors.SharedMessages
import com.portl.admin.services.AdminEventSourceService
import com.portl.commons.models.EventSource
import javax.inject.{Inject, Named}
import play.api.libs.concurrent.InjectedActorSupport

object CollectionRouter {
  final case class Start(eventSource: EventSource)
  final case class Stop(eventSource: EventSource)
  final case class QueryStatus(eventSource: EventSource)
}

class CollectionRouter @Inject()(
    adminEventSourceService: AdminEventSourceService,
    @Named("bandsintown-collector") bandsintownCollector: ActorRef,
    @Named("ticketmaster-collector") ticketmasterCollector: ActorRef,
    @Named("songkick-collector") songkickCollector: ActorRef,
    @Named("ticketfly-collector") ticketflyCollector: ActorRef,
    @Named("eventbrite-collector") eventbriteCollector: ActorRef,
    @Named("meetup-collector") meetupFeedCollector: ActorRef,
) extends Actor
    with InjectedActorSupport {
  import CollectionRouter._

  override def receive: Receive = {
    case Start(serviceName) =>
      getCollector(serviceName) ! SharedMessages.Start
    case Stop(serviceName) =>
      getCollector(serviceName) ! SharedMessages.Stop
    case QueryStatus(serviceName) =>
      getCollector(serviceName) forward SharedMessages.QueryStatus
  }

  private def getCollector(eventSource: EventSource): ActorRef = {
    if (eventSource == EventSource.Bandsintown) bandsintownCollector
    else if (eventSource == EventSource.Ticketmaster) ticketmasterCollector
    else if (eventSource == EventSource.Songkick) songkickCollector
    else if (eventSource == EventSource.Ticketfly) ticketflyCollector
    else if (eventSource == EventSource.Eventbrite) eventbriteCollector
    else if (eventSource == EventSource.Meetup) meetupFeedCollector
    else throw new NotImplementedError(s"EventSource: $eventSource")
  }
}
