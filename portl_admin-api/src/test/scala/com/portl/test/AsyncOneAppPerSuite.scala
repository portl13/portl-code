package com.portl.test

import org.scalatest._
import org.scalatestplus.play.FakeApplicationFactory
import play.api.{Application, Play}

/**
  * The built in [[org.scalatestplus.play.BaseOneAppPerSuite]] doesn't play with the Async* scalatest traits, so this is a copy to allow use with
  * [[Suite]] instead of [[TestSuite]].
  *
  * @author Kahli Burke
  */
trait AsyncOneAppPerSuite extends SuiteMixin { this: Suite with FakeApplicationFactory =>

  /**
    * An implicit instance of `Application`.
    */
  implicit lazy val app: Application = fakeApplication()

  /**
    * Invokes `Play.start`, passing in the `Application` provided by `app`, and places
    * that same `Application` into the `ConfigMap` under the key `org.scalatestplus.play.app` to make it available
    * to nested suites; calls `super.run`; and lastly ensures `Play.stop` is invoked after all tests and nested suites have completed.
    *
    * @param testName an optional name of one test to run. If `None`, all relevant tests should be run.
    *                 I.e., `None` acts like a wildcard that means run all relevant tests in this `Suite`.
    * @param args the `Args` for this run
    * @return a `Status` object that indicates when all tests and nested suites started by this method have completed, and whether or not a failure occurred.
    */
  abstract override def run(testName: Option[String], args: Args): Status = {
    Play.start(app)
    try {
      val newConfigMap = args.configMap + ("org.scalatestplus.play.app" -> app)
      val newArgs = args.copy(configMap = newConfigMap)
      val status = super.run(testName, newArgs)
      status.whenCompleted { _ =>
        Play.stop(app)
      }
      status
    } catch { // In case the suite aborts, ensure the app is stopped
      case ex: Throwable =>
        Play.stop(app)
        throw ex
    }
  }
}
