package com.portl.test.services

import akka.stream.Materializer
import akka.stream.scaladsl.Sink
import com.portl.admin.models.internal
import com.portl.admin.models.internal.MapsToPortlEntity
import com.portl.admin.services.integrations.MappableEventSource
import org.joda.time.DateTime

import scala.concurrent.ExecutionContext

trait MappableEventSourceTests[E <: MapsToPortlEntity[internal.Event]] {
  implicit def executionContext: ExecutionContext
  implicit def materializer: Materializer
  def service: MappableEventSource[E]

  def futureTime: DateTime = DateTime.now.plusDays(1)
  def recentTime: DateTime = DateTime.now.minusDays(1).plusSeconds(1)
  def pastTime: DateTime = DateTime.now.minusDays(2)

  def collectUpcomingEvents = {
    for {
      eventSource <- service.upcomingEventsSource
      events <- eventSource.runWith(Sink.collection[E, Set[E]])
    } yield events
  }
}
