package com.portl.admin.controllers

import com.portl.admin.actions.LoggingActionBuilder
import com.portl.admin.controllers.base.CRUDController
import com.portl.admin.models.portlAdmin.Venue
import javax.inject.Inject
import com.portl.admin.services.VenueCrudService
import play.api.libs.json._
import play.api.mvc._

import scala.concurrent.ExecutionContext

class VenueController @Inject()(cc: ControllerComponents,
                                loggingActionBuilder: LoggingActionBuilder,
                                venueService: VenueCrudService,
                                implicit val ec: ExecutionContext)
    extends CRUDController[Venue](cc, loggingActionBuilder, venueService, ec) {
  // Use external Location formatter and build a new external Venue formatter.
  import com.portl.commons.serializers.External._
  override implicit val format: OFormat[Venue] = Json.format[Venue]

  override def filter(req: Request[AnyContent]): Option[JsObject] =
    req.queryString.get("q").map(_.head).map(venueService.byNameSelector)
}
