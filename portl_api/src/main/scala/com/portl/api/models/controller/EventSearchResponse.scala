package com.portl.api.models.controller

import com.portl.commons.models.StoredEvent
import org.joda.time.DateTime
import play.api.libs.json._
import com.portl.commons.serializers.External._

case class EventSearchItem(
    event: EventP,
    distance: Option[Double]
)

object EventSearchItem {
  implicit val eventSearchItemFormat = Json.format[EventSearchItem]

  def apply(event: StoredEvent, distance: Option[Double]): EventSearchItem =
    EventSearchItem(
      EventP(event),
      distance
    )

  def apply(event: StoredEvent): EventSearchItem = apply(event, None)
}

case class EventSearchResponse(
    latitude: Double,
    longitude: Double,
    maxDistanceMiles: Option[Double] = None,
    startingAfter: Option[DateTime] = None,
    startingWithinDays: Option[Int] = None,
    categories: Option[List[String]] = None,
    items: List[EventSearchItem],
    totalCount: Int,
    page: Int,
    pageSize: Int,
    timestamp: Long = new DateTime().getMillis
)

object EventSearchResponse {
  implicit val eventSearchResponseFormat = Json.format[EventSearchResponse]
}
