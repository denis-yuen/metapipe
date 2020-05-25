import org.apache.logging.log4j.core.config.Configurator
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Level._

import scala.io.Source


name := "metakube-default-it"
organization := "no.uit.sfb"
logLevel := {
  Configurator.setAllLevels(LogManager.getRootLogger.getName, INFO)
  sbt.util.Level.Info
}

resolvers ++= {
  Seq(
    Some(
      "Artifactory" at "https://artifactory.metapipe.uit.no/artifactory/sbt-release-local/"),
    if (version.value.endsWith("-SNAPSHOT"))
      Some(
        "Artifactory-dev" at "https://artifactory.metapipe.uit.no/artifactory/sbt-dev-local/")
    else
      None
  ).flatten
}

credentials += Credentials(Path.userHome / ".sbt" / ".credentials")

//Prevents SBT from exiting when hitting Ctrl-C and a task is running
Global / cancelable := true

val metakubeVersion = Source.fromFile("../../metakubeVersion").mkString

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "3.0.5" % Test,
  "no.uit.sfb" %% "mk-drivers" % metakubeVersion,
  "ch.qos.logback" % "logback-classic" % "1.2.3"
)

enablePlugins(GitVersioning)
useJGit
git.gitlabCiOverride := true
git.targetVersionFile := "../../targetVersion"

enablePlugins(BuildInfoPlugin)
buildInfoKeys := Seq[BuildInfoKey](name, version, scalaVersion, sbtVersion)
buildInfoPackage := s"${organization.value}.info.${name.value.replace('-', '_')}"