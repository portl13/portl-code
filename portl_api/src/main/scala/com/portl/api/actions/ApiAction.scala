package com.portl.api.actions

import java.util.Base64

import javax.inject.Inject
import org.joda.time.DateTime
import org.joda.time.format.DateTimeFormat
import org.slf4j.LoggerFactory
import play.api.Configuration
import play.api.mvc.Results.Unauthorized
import play.api.mvc._

import scala.concurrent.{ExecutionContext, Future}

class ApiAction @Inject()(parser: BodyParsers.Default, configuration: play.api.Configuration)(
    implicit executionContext: ExecutionContext)
    extends ActionBuilderImpl(parser) {
  val log = LoggerFactory.getLogger(getClass)

  val DEPRECATION_DATE_HEADER = "X-API-Deprecation-Date"
  val SETTINGS_KEY_DEPRECATION_DATE = "deprecationDate"
  val SETTINGS_KEY_API_CONSUMERS = "apiConsumers"
  val DEPRECATION_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ssZ"

  private lazy val deprecationDateFormatter = DateTimeFormat.forPattern(DEPRECATION_DATE_FORMAT).withZoneUTC()

  override def invokeBlock[A](request: Request[A], block: Request[A] => Future[Result]): Future[Result] = {
    request.headers.get("Authorization") flatMap {
      parseAuthHeader
    } flatMap {
      validatedCaller
    } match {
      case Some(c) =>
        log.info(s"$c key verified")
        block(request).map { result =>
          deprecationDate(c)
            .map { date =>
              result.withHeaders(DEPRECATION_DATE_HEADER -> date.toString(DEPRECATION_DATE_FORMAT))
            }
            .getOrElse(result)
        }
      case _ => Future.successful(Unauthorized)
    }
  }

  private def parseAuthHeader(authHeader: String): Option[Credentials] = {
    authHeader.split(" ") match {
      case Array("Basic", callerAndKey) =>
        new String(Base64.getDecoder.decode(callerAndKey), "UTF-8").split(":") match {
          case Array(caller, key) => Some(Credentials(caller, key))
          case _                  => None
        }
      case _ => None
    }
  }

  private def validatedCaller(c: Credentials): Option[String] = {
    val consumers = configuration.get[Map[String, Configuration]](SETTINGS_KEY_API_CONSUMERS)
    consumers.get(c.caller) match {
      case Some(config) if config.get[String]("key").equals(c.apiKey) => Some(c.caller)
      case _                                                          => None
    }
  }

  private def deprecationDate(caller: String): Option[DateTime] = {
    val consumers = configuration.get[Map[String, Configuration]](SETTINGS_KEY_API_CONSUMERS)
    consumers.get(caller) match {
      case Some(config) =>
        config.getOptional[String](SETTINGS_KEY_DEPRECATION_DATE).map(DateTime.parse(_, deprecationDateFormatter))
      case _ => None
    }
  }

  override def composeAction[A](action: Action[A]): Action[A] = LoggingAction(super.composeAction(action))

  case class Credentials(caller: String, apiKey: String)
}
