package com.portl.admin.actors.aggregation
import akka.actor.{Actor, ActorRef}
import com.portl.admin.services.AdminEventSourceService
import com.portl.admin.services.integrations._
import com.portl.commons.models.EventSource
import javax.inject.Inject
import play.api.libs.concurrent.InjectedActorSupport

object AggregationRouter {
  final case class Start(eventSource: EventSource)
  final case class Stop(eventSource: EventSource)
  final case class QueryStatus(eventSource: EventSource)
}

class AggregationRouter @Inject()(
    aggregatorFactory: PORTLEventAggregator.Factory,
    adminEventSourceService: AdminEventSourceService,
    bandsintownService: BandsintownService,
    eventbriteService: EventbriteService,
    meetupService: MeetupService,
    songkickService: SongkickService,
    ticketmasterService: TicketmasterService,
    ticketflyService: TicketflyService,
    portlService: PORTLService,
) extends Actor
    with InjectedActorSupport {

  import AggregationRouter._

  override def receive: Receive = {
    case Start(serviceName) =>
      getAggregator(serviceName) ! PORTLEventAggregator.Start
    case Stop(serviceName) =>
      getAggregator(serviceName) ! PORTLEventAggregator.Stop
    case QueryStatus(serviceName) =>
      getAggregator(serviceName) forward PORTLEventAggregator.QueryStatus
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

  private def getAggregator(eventSource: EventSource): ActorRef = {
    val serviceName = eventSource.toString
    val service = eventSources
      .find(_.eventSource == eventSource)
      .getOrElse(throw new NotImplementedError(s"EventSource: $serviceName"))
    def createAggregator: ActorRef = {
      injectedChild(aggregatorFactory(service), serviceName)
    }
    context.child(serviceName).getOrElse(createAggregator)
  }
}
