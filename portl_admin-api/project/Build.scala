import sbt._

/**
  * @author Kahli Burke
  */
object Build {
  val snapshotVersion = settingKey[String]("Version to use (as snapshot base) if no git tag is present.")
}
