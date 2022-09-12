import aether.AetherKeys._
import aether.AetherPlugin
import aether.AetherPlugin.autoImport._
import Build._

name := """portl-commons"""
organization := "com.portl.commons"

scalaVersion := "2.12.3"

resolvers += "Local nexus" at "https://nexus.portl.com/repository/portl-group/"

// Change this to another test framework if you prefer
libraryDependencies ++= Seq(
  "com.typesafe.play" %% "play-json" % "2.6.10",
  "com.typesafe.play" %% "play-json-joda" % "2.6.10",
  "com.typesafe.play" %% "play-iteratees" % "2.6.1",
  "org.reactivemongo" %% "play2-reactivemongo" % "0.20.3-play26",
  "org.reactivemongo" %% "reactivemongo-play-json-compat" % "0.20.3-play26",

  // Unit of measure conversions
  "org.typelevel"  %% "squants"  % "1.3.0",

  "com.beachape" %% "enumeratum" % "1.5.12",

  "org.scalatest" %% "scalatest" % "3.0.5" % "test"
)

// Uncomment to use Akka
//libraryDependencies += "com.typesafe.akka" %% "akka-actor" % "2.3.11"


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
  credentials += Credentials(Path.userHome / ".sbt" / "credentials.portl"),

  // Customize version handling
  git.gitTagToVersionNumber := { tag =>
    if (tag.matches("v[0-9].*") && !tag.matches("v[0-9.]+-.*-.*")) Some(tag drop 1)
    else None
  },

  version in ThisBuild := {
    val tagVersionOpt = (git.gitCurrentTags.value map git.gitTagToVersionNumber.value).reverse.headOption.flatten
    (tagVersionOpt, git.gitCurrentBranch.value) match {
      case (Some(tagVersion), _) =>
        tagVersion
      case (None, branch) if branch != "master" =>
        val sanitizedBranch = branch.replaceAll("/", ".")
        s"$sanitizedBranch-SNAPSHOT"
      case _ =>
        snapshotVersion.value + "-SNAPSHOT"
    }
  }
)

lazy val root = (project in file("."))
  .enablePlugins(
    PlayScala,
    GitVersioning,
    GitBranchPrompt
  )
  .disablePlugins(PlayLayoutPlugin)
  .settings(publishSettings)
