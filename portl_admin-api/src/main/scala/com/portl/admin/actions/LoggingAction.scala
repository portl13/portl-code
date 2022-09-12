package com.portl.admin.actions

import org.slf4j.LoggerFactory
import play.api.mvc._

import scala.concurrent.{ExecutionContext, Future}

case class LoggingAction[A](action: Action[A]) extends Action[A] {
  private val log = LoggerFactory.getLogger(getClass)

  def apply(request: Request[A]): Future[Result] = {
    log.info(s"${request.toString} ${request.body.toString}")
    action(request)
  }

  override lazy val parser: BodyParser[A] = action.parser
  override implicit lazy val executionContext: ExecutionContext = action.executionContext
}
