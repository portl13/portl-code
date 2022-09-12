package com.portl.api.modules

import com.portl.commons.services.IndexCreatorService
import net.codingwell.scalaguice.ScalaModule
import kamon.system.SystemMetrics

class ServiceModule extends ScalaModule {

  override def configure() = {
    bind[IndexCreatorService].asEagerSingleton()
    SystemMetrics.startCollecting()
  }
}
