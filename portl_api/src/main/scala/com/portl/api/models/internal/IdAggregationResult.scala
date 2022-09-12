package com.portl.api.models.internal

import com.portl.commons.models.base.MongoObjectId
import play.api.libs.json.{Json, Reads}

case class IdAggregationResult(
    ids: Seq[MongoObjectId],
    count: Int
)

object IdAggregationResult {
  implicit val reads: Reads[IdAggregationResult] = Json.reads[IdAggregationResult]
}
