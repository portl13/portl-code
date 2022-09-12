name := """admin-api"""

import aether.AetherKeys._
import aether.AetherPlugin
import aether.AetherPlugin.autoImport._
import Build._

enablePlugins(GitVersioning)
enablePlugins(GitBranchPrompt)

import play.sbt.routes.RoutesKeys.routesImport
routesImport += "com.portl.admin.controllers.Binders._"

val installRoot = "/opt/site"
val userAndGroup = "portl"
lazy val rpmSettings = Seq(
  rpmVendor := "Concentric Sky",
  name := "admin-api",
  maintainer := "portl@concentricsky.com",
  packageSummary := "PORTL Admin Server",
  packageDescription := packageSummary.value,
  rpmGroup := Some("Applications/Internet"),
  rpmLicense := Some("Proprietary"),
  javaOptions in Universal += "-Dpidfile.path=/dev/null",
  daemonUser in Linux := userAndGroup,
  daemonGroup in Linux := userAndGroup,
  retryTimeout in Rpm := 10,
  crossPaths := false, //needed if you want to remove the scala version from the artifact name
  aetherArtifact := AetherPlugin
    .createArtifact((packagedArtifacts in Rpm).value, aetherCoordinates.value, (Keys.`packageBin` in Rpm).value),

  snapshotVersion in ThisBuild := scala.io.Source.fromFile(baseDirectory.value / "version.txt").mkString.trim,
  version in ThisBuild := {
    val baseVersion = sys.env.getOrElse("BUILD_VERSION", snapshotVersion.value)
      .replaceAll("/", ".")
      .replaceAll("-", "_")
    val suffix = if (sys.env.contains("BUILD_VERSION")) "" else "-SNAPSHOT"
    baseVersion + suffix
  }
)

lazy val publishSettings = Seq(
  publishMavenStyle := true,
  publishArtifact in Test := false,
  publishTo := {
    val baseUrl = "http://nexus.portl.com:8081/repository/portl-"
    if (version.value.trim.endsWith("SNAPSHOT"))
      Some("snapshots" at baseUrl + "snapshots/")
    else
      Some("releases" at baseUrl + "releases/")
  },
  credentials += Credentials(Path.userHome / ".sbt" / "credentials.portl")
)

lazy val distSettings = Seq(
  publishArtifact in (Compile, packageDoc) := false,
  publishArtifact in (Compile, packageSrc) := false
)

lazy val buildInfoSettings = Seq(
  buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion),
  buildInfoKeys ++= Seq[BuildInfoKey](
    "gitTag" -> git.gitDescribedVersion.value.getOrElse("n/a"),
    "gitVersion" -> git.gitHeadCommit.value.getOrElse("n/a"),
    "gitBranch" -> git.gitCurrentBranch.value
  ),
  buildInfoObject := normalizedName.value.split("-").map(_.capitalize).mkString("") + "BuildInfo",
  buildInfoPackage := "com.portl.admin.build",
  buildInfoOptions += BuildInfoOption.ToMap,
  buildInfoOptions += BuildInfoOption.ToJson
)

lazy val root = (project in file("."))
  .enablePlugins(
    PlayScala,
    JavaServerAppPackaging,
    RpmPlugin,
    SystemdPlugin,
    RpmDeployPlugin,
    AetherPlugin,
    BuildInfoPlugin,
    JavaAgent
  )

  .disablePlugins(PlayLayoutPlugin)

  .settings(publishSettings)
  .settings(rpmSettings)
  .settings(distSettings)
  .settings(overridePublishBothSettings)
  .settings(buildInfoSettings)

resolvers += Resolver.sonatypeRepo("snapshots")
resolvers += "Local nexus" at "https://nexus.portl.com/repository/portl-group/"
// These resolvers would be required, but they are instead included as Nexus proxies.
//resolvers += Resolver.bintrayRepo("kamon-io", "releases")
//resolvers += "jitpack" at "https://jitpack.io"

scalaVersion := "2.12.3"

libraryDependencies ++= Seq(
  guice,
  ws,
  "org.scalatestplus.play" %% "scalatestplus-play" % "3.0.0" % Test,
  "de.leanovate.play-mockws" %% "play-mockws" % "2.6.2" % Test,

  "org.reactivemongo" %% "play2-reactivemongo" % "0.20.3-play26",
  "org.reactivemongo" %% "reactivemongo-akkastream" % "0.20.3",
  "com.typesafe.play" %% "play-json" % "2.6.10",
  "com.typesafe.play" %% "play-json-joda" % "2.6.10",

  // Unit of measure conversions
  "org.typelevel"  %% "squants"  % "1.3.0",

  "com.beachape" %% "enumeratum" % "1.5.12",
  "net.codingwell" %% "scala-guice" % "4.1.0",
  "com.typesafe.akka" %% "akka-cluster-tools" % "2.5.25",
  "org.codehaus.janino" % "janino" % "2.6.1",

  // logging
  "ch.qos.logback" % "logback-classic" % "1.2.3",
  "de.siegmar" % "logback-gelf" % "1.1.0",

  // code shared with data apire
  "com.portl.commons" %% "portl-commons" % "2.7.0",

  // this is for serializing case classes with >22 params
  "ai.x" %% "play-json-extensions" % "0.10.0",

  "com.iheart" %% "ficus" % "1.4.3",

  "com.javadocmd" % "simplelatlng" % "1.3.1",

  // Async stream-based json parsing (TM bulk operation)
  "org.spire-math" %% "jawn-parser" % "0.11.0",
  "org.spire-math" %% "jawn-play" % "0.11.0",

  // meetup feed processor
  "com.typesafe.akka" %% "akka-actor" % "2.5.25",
  "com.enragedginger" %% "akka-quartz-scheduler" % "1.7.0-akka-2.5.x",
  "com.typesafe.akka" %% "akka-testkit" % "2.5.25" % Test,

  // timezone lookup by location
  "net.iakovlev" % "timeshape" % "2018d.6",

  // hashing Bandsintown venue data to derive an id
  "commons-codec" % "commons-codec" % "1.11",

  // Geocode venues for better deduplication
  //"com.opencagedata" %% "scala-opencage-geocoder" % "1.1.1",
  //temporarily use our library with fix for https://github.com/OpenCageData/scala-opencage-geocoder/issues/6
  "com.csky" %% "scala-opencage-geocoder" % "1.1.2",

  // Generate signed S3 URLs for image upload from admin ui
  "com.github.seratch" %% "awscala-s3" % "0.8.+",

  // Stream-based CSV parsing
  "com.github.tototoshi" %% "scala-csv" % "1.3.5",

  // tracing / metrics support
  "io.kamon" %% "kamon-core" % "1.1.2",
  "io.kamon" %% "kamon-play-2.6" % "1.1.0",
  "io.kamon" %% "kamon-system-metrics" % "1.0.0",
  "io.kamon" %% "kamon-influxdb" % "1.0.1",
  "io.kamon" %% "kamon-zipkin" % "1.0.0",
  "com.github.jtjeferreira" %% "kamon-mongo" % "0.0.4",
  "org.aspectj" % "aspectjweaver" % "1.9.1"
)

javaAgents += "org.aspectj" % "aspectjweaver" % "1.9.1"
javaOptions in Universal += "-Dorg.aspectj.tracing.factory=default"

testOptions in Test += Tests.Argument("-oD")
fork in Test := false
parallelExecution in Test := false

fork in run := true
