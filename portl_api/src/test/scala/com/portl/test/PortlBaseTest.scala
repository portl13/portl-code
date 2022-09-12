package com.portl.test

import org.scalatest._
import org.scalatest.concurrent.ScalaFutures
import org.scalatestplus.play.WsScalaTestClient
import org.scalatestplus.play.guice.GuiceFakeApplicationFactory
import play.api.inject.guice.GuiceApplicationBuilder
import play.api.libs.json.JsObject
import play.api.{Configuration, Environment}
import play.modules.reactivemongo.ReactiveMongoApi
import reactivemongo.play.json.compat._
import reactivemongo.play.json.collection.JSONCollection

import scala.concurrent.Future
import scala.reflect.ClassTag

/**
  * Base test class
  *
  * Note: It would be useful to extend BeforeAndAfter or BeforeAndAfterEach to do stuff like clear out db collections.
  * The default execution context in scalatest-play 3.0+ is single threaded, so async operations in the corresponding
  * methods don't work! They never get an execution thread, and the await times out. Using the global execution context
  * instead is tempting, but it can result in multiple tests trying to run at once:
  *
  * [info]   java.util.ConcurrentModificationException: Two threads have apparently attempted to run a suite at the same time. ...
  *
  * Instead, we offer utility functions to reset a collection and call them from within the test cases.
  *
  * @author Kahli Burke
  */
abstract class PortlBaseTest
    extends AsyncWordSpec
    with ScalaFutures
    with MustMatchers
    with OptionValues
    with WsScalaTestClient
    with AsyncOneAppPerSuite
    with GuiceFakeApplicationFactory {

  val configOverrides: Map[String, AnyRef] = Map.empty
  val fullOverrides = Map(
    "mongodb.dbs.main" -> "portl-test",
    "play.http.secret.key" -> "some-key",
  ) ++ configOverrides
  def config = Configuration.load(Environment.simple(), fullOverrides)

  override def fakeApplication() = {
    GuiceApplicationBuilder()
      .configure(config)
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
      _ <- Future.sequence(objects.map(o => collection.insert(ordered = false).one(o)))
    } yield ()
  }
}
