package com.portl.api.modules

import com.portl.api.services.background.{
  ClusteredExampleBackgroundService,
  ExampleBackgroundService,
  LocalExampleBackgroundService
}
import net.codingwell.scalaguice.ScalaModule

/**
  * @author Kahli Burke
  */
class LocalBackgroundServiceModule extends ScalaModule {
  override def configure() = {
    bind[ExampleBackgroundService].to[LocalExampleBackgroundService].asEagerSingleton()
  }
}

/**
  * @author Kahli Burke
  */
class ClusteredBackgroundServiceModule extends ScalaModule {
  override def configure() = {
    bind[ExampleBackgroundService].to[ClusteredExampleBackgroundService].asEagerSingleton()
  }
}
