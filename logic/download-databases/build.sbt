import org.apache.logging.log4j.core.config.Configurator
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Level._


name := "ref-databases-mgmt"
scalaVersion := "2.12.8"
organization     := "no.uit.sfb"
organizationName := "SfB"
logLevel := {
  Configurator.setAllLevels(LogManager.getRootLogger.getName, INFO)
  sbt.util.Level.Info
}

maintainer := "mmp@uit.no"

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

publishTo := {
  if (version.value.endsWith("-SNAPSHOT"))
    Some("Artifactory Realm" at "https://artifactory.metapipe.uit.no/artifactory/sbt-dev-local;build.timestamp=" + new java.util.Date().getTime)
  else
    Some("Artifactory Realm" at "https://artifactory.metapipe.uit.no/artifactory/sbt-release-local")
}

credentials += Credentials(Path.userHome / ".sbt" / ".credentials")

enablePlugins(GitVersioning)
useJGit
git.gitlabCiOverride := true
git.targetVersionFile := "../../targetVersion"

enablePlugins(DockerPlugin, JavaAppPackaging)

dockerLabels := Map("gitCommit" -> s"${git.formattedShaVersion.value.getOrElse("unknown")}@${git.gitCurrentBranch.value}")
dockerRepository in Docker := Some("registry.gitlab.com")
dockerUsername in Docker := Some("uit-sfb/mk-metapipe-logic")
//dockerChmodType := DockerChmodType.Custom("u=rX,g=rX,o=rX")
daemonUser in Docker := "sfb" //"in Docker" needed for this parameter

lazy val scalaUtilsVer = "0.2.1"

libraryDependencies ++= Seq(
  "com.github.scopt" %% "scopt" % "4.0.0-RC2",
  "no.uit.sfb" %% "scala-utils-common" % scalaUtilsVer,
  "no.uit.sfb" %% "scala-utils-json" % scalaUtilsVer,
  "com.typesafe.scala-logging" %% "scala-logging" % "3.9.2",
  "ch.qos.logback" % "logback-classic" % "1.2.3"
)

enablePlugins(BuildInfoPlugin)
buildInfoKeys := Seq[BuildInfoKey](
  name,
  version,
  scalaVersion,
  sbtVersion,
  git.formattedShaVersion
)
buildInfoPackage := s"${organization.value}.info.${name.value.replace('-', '_')}"