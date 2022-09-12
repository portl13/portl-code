package com.portl.admin.actors.geocoding

import akka.actor.{Actor, ActorRef}
import com.portl.admin.services.AdminEventSourceService
import com.portl.admin.services.integrations._
import com.portl.commons.models.EventSource
import javax.inject.Inject
import play.api.libs.concurrent.InjectedActorSupport


class GeocodingRouter @Inject()(
     geocoderFactory: SourceVenueGeocoder.Factory,
     adminEventSourceService: AdminEventSourceService,
     bandsintownService: BandsintownService,
     eventbriteService: EventbriteService,
     meetupService: MeetupService,
     songkickService: SongkickService,
     ticketmasterService: TicketmasterService,
     ticketflyService: TicketflyService,
) extends Actor
    with InjectedActorSupport {

  import com.portl.admin.actors.SharedMessages._

  override def receive: Receive = {
    case Start(serviceName) =>
      getGeocoder(serviceName) ! Start
    case Stop(serviceName) =>
      getGeocoder(serviceName) ! Stop
    case QueryStatus(serviceName) =>
      getGeocoder(serviceName) forward QueryStatus
  }

  private val eventSources = Seq(
    adminEventSourceService,
    bandsintownService,
    eventbriteService,
    meetupService,
    songkickService,
    ticketflyService,
    ticketmasterService
  )

  private def getGeocoder(eventSource: EventSource): ActorRef = {
    val serviceName = eventSource.toString
    val service = eventSources
      .find(_.eventSource == eventSource)
      .getOrElse(throw new NotImplementedError(s"EventSource: $serviceName"))
    def createGeocoder: ActorRef = {
      injectedChild(geocoderFactory(service), serviceName)
    }
    context.child(serviceName).getOrElse(createGeocoder)
  }
}
