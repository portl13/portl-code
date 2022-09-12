package com.portl.api.services

import com.portl.api.services.queries.Queries.ArtistByName
import javax.inject.Inject
import com.portl.commons.models.StoredArtist
import com.portl.commons.services.{PaginationParams, SingleCollectionService}
import play.api.libs.json._
import play.modules.reactivemongo.ReactiveMongoApi

import scala.concurrent.{ExecutionContext, Future}

class ArtistService @Inject()(implicit val executionContext: ExecutionContext, val reactiveMongoApi: ReactiveMongoApi)
    extends SingleCollectionService[StoredArtist] {
  val collectionName = "artists"

  def search(name: String, pagination: Option[PaginationParams] = None): Future[List[StoredArtist]] = {
    val query = ArtistByName(name)
    val sort = Json.obj("name" -> 1)

    withCollection {
      pagination match {
        case Some(p) =>
          _.findListSortedPaginated[ArtistByName, StoredArtist](
            query,
            sort,
            p.page,
            p.pageSize
          )
        case _ =>
          _.findListSorted[ArtistByName, StoredArtist](query, sort)
      }
    }
  }
}
