package com.portl.admin.services.background

import com.portl.admin.models.backgroundTask.{Task, TaskStatus}
import com.portl.commons.serializers.Mongo._
import com.portl.commons.services.SingleCollectionService
import javax.inject.Inject
import org.joda.time.DateTime
import play.api.libs.json._
import play.modules.reactivemongo._
import reactivemongo.play.json.compat._

import scala.concurrent.{ExecutionContext, Future}

class BackgroundTaskService @Inject()(configuration: play.api.Configuration,
                                      implicit val executionContext: ExecutionContext,
                                      @NamedDatabase("backgroundTasks") val reactiveMongoApi: ReactiveMongoApi)
    extends SingleCollectionService[Task] {

  override val collectionName: String = "tasks"

  def active: Future[List[Task]] = {
    withCollection { c =>
      c.findListSorted[JsObject, Task](Json.obj("status" -> TaskStatus.InProgress), Json.obj("created" -> -1))
    }
  }

  def today: Future[List[Task]] = {
    withCollection { c =>
      c.findListSorted[JsObject, Task](
        Json.obj(
          "created" -> Json.obj(
            "$gt" -> Json.toJson(DateTime.now().toLocalDate.toDateTimeAtStartOfDay(DateTime.now().getZone))
          )),
        Json.obj("created" -> -1))
    }
  }
}
