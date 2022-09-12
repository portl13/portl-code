package com.portl.admin.modules

import com.portl.admin.actors.aggregation.{AggregationRouter, AggregationScheduler, PORTLEventAggregator}
import com.portl.admin.actors.collection._
import com.portl.admin.actors.geocoding.{GeocodingRouter, GeocodingScheduler, SourceVenueGeocoder}
import com.portl.admin.actors.importing.ArtistImageCacher
import com.portl.admin.actors.dedupe.{PruneDuplicateEvents, PruneDuplicateVenues}
import com.portl.admin.actors.{EventOffloader, PeriodicTaskScheduler}
import com.portl.admin.services.TimezoneResolver
import com.portl.commons.services.IndexCreatorService
import kamon.system.SystemMetrics
import net.codingwell.scalaguice.ScalaModule
import play.api.libs.concurrent.AkkaGuiceSupport

class ServiceModule extends ScalaModule with AkkaGuiceSupport {

  override def configure() = {
    bind[IndexCreatorService].asEagerSingleton()
    bind[TimezoneResolver].asEagerSingleton()

    bindActor[AggregationScheduler]("aggregation-scheduler")
    bindActor[AggregationRouter]("aggregation-router")
    bindActorFactory[PORTLEventAggregator, PORTLEventAggregator.Factory]

    bindActor[BandsintownCollector]("bandsintown-collector")
    bindActor[TicketmasterCollector]("ticketmaster-collector")
    bindActor[SongkickCollector]("songkick-collector")
    bindActor[TicketflyCollector]("ticketfly-collector")
    bindActor[EventbriteCollector]("eventbrite-collector")
    bindActor[MeetupFeedCollector]("meetup-collector")
    bindActor[CollectionScheduler]("collection-scheduler")
    bindActor[CollectionRouter]("collection-router")

    bindActor[PeriodicTaskScheduler]("periodic-task-scheduler")
    bindActor[EventOffloader]("event-offloader")

    bindActor[GeocodingScheduler]("geocoding-scheduler")
    bindActor[GeocodingRouter]("geocoding-router")
    bindActorFactory[SourceVenueGeocoder, SourceVenueGeocoder.Factory]

    bindActor[ArtistImageCacher]("artist-image-cacher")

    bindActor[PruneDuplicateVenues]("prune-duplicate-venues")
    bindActor[PruneDuplicateEvents]("prune-duplicate-events")

    SystemMetrics.startCollecting()
  }
}
