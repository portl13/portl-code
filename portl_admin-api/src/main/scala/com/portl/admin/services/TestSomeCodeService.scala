package com.portl.admin.services

import akka.http.scaladsl.model.HttpHeader.ParsingResult.Ok
import akka.Done
import akka.stream.Materializer
import akka.stream.scaladsl.Source
import com.portl.admin.models.internal.{Event, Venue}
import com.portl.admin.models.meetup.{Event => MeetupEvent}
import com.portl.commons.models.{EventSource, SourceIdentifier}
import javax.inject.Inject
import play.modules.reactivemongo.{NamedDatabase, ReactiveMongoApi}
import com.portl.commons.services.MongoService
import com.portl.commons.services.queries.CommonQueries.ByExternalId
import play.api.libs.json.{JsObject, Json, OFormat, OWrites}
import reactivemongo.akkastream.cursorProducer
import reactivemongo.api.{Cursor, ReadPreference}
import reactivemongo.api.commands.UpdateWriteResult
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.{ExecutionContext, Future}
import scala.util.{Failure, Success}

class TestSomeCodeService @Inject()(
                                     @NamedDatabase("data") val reactiveMongoApi: ReactiveMongoApi,
                                     @NamedDatabase("meetup") val reactiveMongoMeetup: ReactiveMongoApi,
                                     implicit val executionContext: ExecutionContext,
                                     implicit val materializer: Materializer
                                   ) extends MongoService {

  def getSpecificVenue(source: EventSource, id: String): Future[Option[Venue]] = {
    val externalId = SourceIdentifier(source, id)
    implicit val format: OFormat[Venue] = Venue.venueFormat
    for {
      c <- collection("venues")
      venue <- c.findOne[ByExternalId, Venue](ByExternalId(externalId))
    } yield venue
  }

}

private case class MyById(id: String)
private object MyById {
  implicit val writes: OWrites[MyById] = (byId: MyById) => {
    Json.obj(
      "_id" -> byId.id
    )
  }
}
