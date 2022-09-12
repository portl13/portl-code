enablePlugins(GatlingPlugin)

scalaVersion := "2.12.8"
resolvers += Resolver.url("jb-bintray", url("http://dl.bintray.com/jetbrains/sbt-plugins"))(Resolver.ivyStylePatterns)

scalacOptions := Seq(
  "-encoding", "UTF-8", "-target:jvm-1.8", "-deprecation",
  "-feature", "-unchecked", "-language:implicitConversions", "-language:postfixOps")

libraryDependencies += "io.gatling.highcharts" % "gatling-charts-highcharts" % "3.0.2" % "test,it"
libraryDependencies += "io.gatling"            % "gatling-test-framework"    % "3.0.2" % "test,it"
libraryDependencies += "com.typesafe.play" % "play-json-joda_2.12" % "2.6.5"
libraryDependencies += "com.portl.commons" %% "portl-commons" % "2.0.0"
