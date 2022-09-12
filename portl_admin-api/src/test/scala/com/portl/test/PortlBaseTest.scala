package com.portl.test

import org.scalatest._
import org.scalatest.concurrent.ScalaFutures
import org.scalatestplus.play.WsScalaTestClient
import org.scalatestplus.play.guice.GuiceFakeApplicationFactory
import play.api.inject.guice.{GuiceApplicationBuilder, GuiceableModule}
import play.api.libs.json.JsObject
import play.api.{Configuration, Environment}
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.play.json.collection.JSONCollection
import reactivemongo.play.json.compat._

import scala.concurrent.Future
import scala.reflect.ClassTag

/**
  * Base test class
  * @author Kahli Burke
  */
abstract class PortlBaseTest
    extends AsyncWordSpec
    with MustMatchers
    with ScalaFutures
    with OptionValues
    with WsScalaTestClient
    with AsyncOneAppPerSuite
    with GuiceFakeApplicationFactory
    with BeforeAndAfter {

  val configOverrides: Map[String, AnyRef] = Map.empty
  val fullOverrides = Map(
    "mongodb.dbs.main" -> "portlAdmin-test",
    "mongodb.dbs.data" -> "portl-test",
    "mongodb.dbs.eventbrite" -> "eventbrite-test",
    "mongodb.dbs.ticketmaster" -> "ticketmaster-test",
    "mongodb.dbs.songkick" -> "songkick-test",
    "mongodb.dbs.ticketfly" -> "ticketfly-test",
    "mongodb.dbs.meetup" -> "meetup-test",
    "mongodb.dbs.backgroundTasks" -> "backgroundTasks-test",
    "play.http.secret.key" -> "some-key",
    "com.portl.integrations.eventbrite.token" -> "some-token",
    "com.portl.integrations.songkick.token" -> "some-token",
    "com.portl.integrations.ticketmaster.token" -> "some-token",
    "com.portl.integrations.meetup.token" -> "some-token",
  ) ++ configOverrides
  def config = Configuration.load(Environment.simple(), fullOverrides)

  def moduleOverrides: Seq[GuiceableModule] = Seq.empty
  def fullModuleOverrides: Seq[GuiceableModule] = Seq.empty ++ moduleOverrides

  override def fakeApplication() = {
    // "com.github.seratch" %% "awscala-s3" % "0.8.+"
    // The S3 library uses the AWS Java SDK, which searches for credentials in these places:
    // https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html
    // Set them as a system property during testing to avoid crashes when they are unavailable.
    System.setProperty("aws.accessKeyId", "fake")
    System.setProperty("aws.secretKey", "fake-key")
    GuiceApplicationBuilder()
      .configure(config)
      .overrides(fullModuleOverrides: _*)
      .build()
  }

  def injectorObj[T: ClassTag] =
    app.injector.instanceOf[T]

  def resetCollection(collection: JSONCollection): Future[Unit] =
    collection.delete().one(JsObject.empty).map(_ => ())

  def resetCollection(dbName: String, collectionName: String): Future[Unit] = {
    val mongo = injectorObj[ReactiveMongoApi]
    mongo.connection
      .database(dbName)
      .flatMap { db =>
        resetCollection(db.collection[JSONCollection](collectionName))
      }
  }

  def resetCollectionWith[T](collection: JSONCollection, objects: Seq[T])(
      implicit writer: collection.pack.Writer[T]) = {
    for {
      _ <- resetCollection(collection)
      _ <- Future.sequence(objects.map(collection.insert(ordered = false).one(_)))
    } yield ()
  }

}
