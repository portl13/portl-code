name := """portl-api"""

import aether.AetherKeys._
import aether.AetherPlugin
import aether.AetherPlugin.autoImport._
import Build._

enablePlugins(GitVersioning)
enablePlugins(GitBranchPrompt)


val installRoot = "/opt/site"
val userAndGroup = "portl"
lazy val rpmSettings = Seq(
  rpmVendor := "Concentric Sky",
  name := "portl-api",
  maintainer := "portl@concentricsky.com",
  packageSummary := "PORTL API Server",
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
  buildInfoPackage := "com.portl.api.build",
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
    GatlingPlugin,
    JavaAgent
  )

  .disablePlugins(PlayLayoutPlugin)

  .settings(publishSettings)
  .settings(rpmSettings)
  .settings(distSettings)
  .settings(overridePublishBothSettings)
  .settings(buildInfoSettings)

scalaVersion := "2.12.3"

// These resolvers would be required, but they are instead included as Nexus proxies.
//resolvers += Resolver.bintrayRepo("kamon-io", "releases")
//resolvers += "jitpack" at "https://jitpack.io"

libraryDependencies ++= Seq(
  guice,
  ws,
  "org.scalatestplus.play" %% "scalatestplus-play" % "3.0.0" % Test,
  "org.reactivemongo" %% "play2-reactivemongo" % "0.20.3-play26",
  "org.reactivemongo" %% "reactivemongo-akkastream" % "0.20.3",
  "com.typesafe.play" %% "play-json" % "2.6.10",

  // https://mvnrepository.com/artifact/com.typesafe.play/play-json-joda_2.12
  "com.typesafe.play" % "play-json-joda_2.12" % "2.6.10",

  // Unit of measure conversions
  "org.typelevel"  %% "squants"  % "1.3.0",

  "com.beachape" %% "enumeratum" % "1.5.12",
  "net.codingwell" %% "scala-guice" % "4.1.0",
  "com.typesafe.akka" %% "akka-cluster-tools" % "2.5.25",
  "org.codehaus.janino" % "janino" % "2.6.1",

  // logging
  "ch.qos.logback" % "logback-classic" % "1.2.3",
  "de.siegmar" % "logback-gelf" % "1.0.4",

  // code shared with admin api
  "com.portl.commons" %% "portl-commons" % "4fa8622ba306764aa9a178d06b3fa6d27fa67ce4-SNAPSHOT",

  // this is for serializing case classes with >22 params
  "ai.x" %% "play-json-extensions" % "0.10.0",

  "com.iheart" %% "ficus" % "1.4.3",

  "com.javadocmd" % "simplelatlng" % "1.3.1",

  // Async stream-based json parsing (TM bulk operation)
  "org.spire-math" %% "jawn-parser" % "0.12.1",
  "org.spire-math" %% "jawn-play" % "0.12.1",

  // load / stress testing
  "io.gatling.highcharts" % "gatling-charts-highcharts" % "2.3.0" % "test,it",
  "io.gatling" % "gatling-test-framework" % "2.3.0" % "test,it",

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
fork in GatlingIt := false
parallelExecution in Test := false

fork in run := true
