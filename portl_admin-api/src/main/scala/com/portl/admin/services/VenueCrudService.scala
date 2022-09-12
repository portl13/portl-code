package com.portl.admin.services

import javax.inject.Inject
import com.portl.admin.models.portlAdmin.Venue
import play.api.libs.json.{JsObject, Json, OFormat}
import play.modules.reactivemongo.ReactiveMongoApi

import scala.concurrent.ExecutionContext

class VenueCrudService @Inject()(implicit val executionContext: ExecutionContext,
                                 val reactiveMongoApi: ReactiveMongoApi,
                                 configuration: play.api.Configuration)
    extends AdminCrudService[Venue] {
  val collectionName = "venues"
  override implicit val format: OFormat[Venue] = Venue.venueFormat

  def byNameSelector(name: String): JsObject =
    Json.obj("$text" -> Json.obj("$search" -> s""""$name""""))
}
