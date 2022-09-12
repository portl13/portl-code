package com.portl.api.services

import com.portl.api.models.internal.IdAggregationResult
import com.portl.api.services.queries.Queries
import com.portl.api.services.queries.Queries.{ByCaseInsensitiveSubstring, VenueByName}
import javax.inject.Inject
import com.portl.commons.models._
import com.portl.commons.services.{PaginationParams, SingleCollectionService}
import play.api.libs.json._
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.api.{Cursor, CursorOptions, ReadConcern, ReadPreference}
import squants.Length
import squants.space.LengthConversions._

import scala.concurrent.{ExecutionContext, Future}

class VenueService @Inject()(implicit val executionContext: ExecutionContext,
                             val reactiveMongoApi: ReactiveMongoApi,
                             configuration: play.api.Configuration)
    extends SingleCollectionService[StoredVenue] {
  val collectionName = "venues"
  private val defaultSearchRadius = configuration.underlying.getInt("com.portl.api.defaultSearchRadiusMiles").miles

  def search(name: String, pagination: Option[PaginationParams] = None): Future[List[StoredVenue]] = {
    val query = VenueByName(name)
    val sort = Json.obj("name" -> 1)

    withCollection { c =>
      pagination match {
        case Some(p) =>
          c.findListSortedPaginated[VenueByName, StoredVenue](
            query,
            sort,
            p.page,
            p.pageSize
          )
        case _ => c.findListSorted[VenueByName, StoredVenue](query, sort)
      }
    }
  }

  def findPaginatedIdsNear(name: String,
                           location: Location,
                           pagination: Option[PaginationParams] = None,
                           maxDistance: Option[Length] = None): Future[IdAggregationResult] = {
    val dist = maxDistance.getOrElse(defaultSearchRadius)
    val query = Json.toJsObject(ByCaseInsensitiveSubstring("name", name)) ++ Queries.notMarkedForDeletion
    val offset = pagination.map(p => p.page * p.pageSize).getOrElse(0)
    val limit = pagination.map(_.pageSize).getOrElse(Int.MaxValue)

    withCollection { c =>
      import c.BatchCommands.AggregationFramework._

      c.withReadPreference(ReadPreference.secondary)
        .aggregatorContext[IdAggregationResult](
          c.geoNear(location, Some(dist), Some("computedDistance"), Some(query)),
          List(
            // Create one group with an overall count and list of all result ids.
            Group(JsNull)("count" -> SumAll, "ids" -> PushField("_id")),
            // Slice the result ids based on the provided pagination.
            Project(Json.obj("count" -> 1, "ids" -> Json.obj("$slice" -> Json.arr("$ids", offset, limit))))
          ),
          explain = false,
          allowDiskUse = true,
          bypassDocumentValidation = false,
          readConcern = ReadConcern.Local,
          readPreference = c.db.connection.options.readPreference,
          writeConcern = c.db.connection.options.writeConcern,
          batchSize = None,
          cursorOptions = CursorOptions.empty,
          maxTime = None,
          hint = None,
          comment = None,
          collation = None
        )
        .prepared
        .cursor
        .head
    }
  }

  def searchNear(name: String,
                 location: Location,
                 pagination: Option[PaginationParams] = None,
                 maxDistance: Option[Length] = None): Future[List[StoredVenue]] = {
    val dist = maxDistance.getOrElse(defaultSearchRadius)
    val query = Json.toJsObject(ByCaseInsensitiveSubstring("name", name)) ++ Queries.notMarkedForDeletion

    withCollection { c =>
      import c.BatchCommands.AggregationFramework.{Skip, Limit}

      c.withReadPreference(ReadPreference.secondary)
        .aggregatorContext[StoredVenue](
          c.geoNear(location, Some(dist), Some("computedDistance"), Some(query)),
          pagination match {
            case Some(p) => List(Skip(p.page * p.pageSize), Limit(p.pageSize))
            case _       => Nil
          },
          explain = false,
          allowDiskUse = true,
          bypassDocumentValidation = false,
          readConcern = ReadConcern.Local,
          readPreference = c.db.connection.options.readPreference,
          writeConcern = c.db.connection.options.writeConcern,
          batchSize = None,
          cursorOptions = CursorOptions.empty,
          maxTime = None,
          hint = None,
          comment = None,
          collation = None
        )
        .prepared
        .cursor
        .collect[List](-1, Cursor.ContOnError((_, ex: Throwable) => {
          log.warn(s"Failed to deserialize Mongo entity", ex)
        }))
    }
  }
}
