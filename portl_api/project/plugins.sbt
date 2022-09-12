// The Play plugin
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.6.5")

// rpm builds
addSbtPlugin("com.typesafe.sbt" % "sbt-native-packager" % "1.3.1")
addSbtPlugin("no.arktekk.sbt" % "aether-deploy" % "0.20.0")
addSbtPlugin("com.typesafe.sbt" % "sbt-git" % "0.9.3")
addSbtPlugin("com.eed3si9n" % "sbt-buildinfo" % "0.7.0")

// load tests
addSbtPlugin("io.gatling" % "gatling-sbt" % "2.2.2")

// support AspectJ Weaver in dev mode and in sbt-native-packager
addSbtPlugin("io.kamon" % "sbt-aspectj-runner-play-2.6" % "1.1.1")
addSbtPlugin("com.lightbend.sbt" % "sbt-javaagent" % "0.1.4")
