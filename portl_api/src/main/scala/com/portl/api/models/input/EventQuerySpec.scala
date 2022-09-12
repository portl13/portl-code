package com.portl.api.models.input

import com.portl.commons.serializers.External._
import org.joda.time.DateTime
import play.api.libs.json._

case class EventQuerySpec(
    location: Location,
    maxDistanceMiles: Option[Double] = None,
    startingAfter: Option[DateTime] = None,
    startingWithinDays: Option[Int] = None,
    categories: Option[List[String]] = None,
    page: Int,
    pageSize: Int
    //                          artistId: Option[SourceIdentifier] = None,
    //                          venueId: Option[SourceIdentifier] = None,
)

object EventQuerySpec {
  implicit val eventQuerySpecFormat: OFormat[EventQuerySpec] = Json.format[EventQuerySpec]
}
