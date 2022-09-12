package com.portl.admin.actions

import javax.inject.Inject
import play.api.mvc._

import scala.concurrent.ExecutionContext

class LoggingActionBuilder @Inject()(parser: BodyParsers.Default)(implicit executionContext: ExecutionContext)
    extends ActionBuilderImpl(parser) {

  override def composeAction[A](action: Action[A]): Action[A] = LoggingAction(super.composeAction(action))
}
