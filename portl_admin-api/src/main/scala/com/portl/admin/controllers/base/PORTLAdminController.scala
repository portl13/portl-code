package com.portl.admin.controllers.base
import com.portl.admin.actions.LoggingActionBuilder
import org.slf4j.LoggerFactory
import play.api.mvc._

abstract class PORTLAdminController(cc: ControllerComponents, loggingActionBuilder: LoggingActionBuilder)
    extends AbstractController(cc) {

  val log = LoggerFactory.getLogger(getClass)
  override def Action: ActionBuilder[Request, AnyContent] = loggingActionBuilder
}
