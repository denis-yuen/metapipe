name := "rrnapred"
scalaVersion := "2.12.8"
organization := "no.uit.sfb"
organizationName := "SfB"

enablePlugins(GitVersioning)
useJGit
git.gitlabCiOverride := true
git.targetVersionFile := "../../targetVersion"

ThisBuild / resolvers ++= {
  Seq(Some("Artifactory" at "https://artifactory.metapipe.uit.no/artifactory/sbt-release-local/"),
    if ((version).value.endsWith("-SNAPSHOT"))
      Some("Artifactory-dev" at "https://artifactory.metapipe.uit.no/artifactory/sbt-dev-local/")
    else
      None
  ).flatten
}

lazy val scalaUtilsVersion = "0.2.1"

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "3.0.5" % Test,
  "com.github.scopt" %% "scopt" % "4.0.0-RC2",
  "no.uit.sfb" %% "scala-utils-genomiclib" % scalaUtilsVersion,
  "no.uit.sfb" %% "scala-utils-common" % scalaUtilsVersion,
  "ch.qos.logback" % "logback-classic" % "1.2.3"
)


enablePlugins(JavaAppPackaging, DockerPlugin)

val genomicToolRegistry = "registry.gitlab.com/uit-sfb/genomic-tools"

dockerRepository in Docker := Some("registry.gitlab.com")
dockerUsername in Docker := Some("uit-sfb/mk-metapipe-logic")
dockerAlias := {
  dockerAlias.value.copy(tag = Some(s"${version.value}"))
}
dockerBaseImage := s"anapsix/alpine-java:8_server-jre"
import com.typesafe.sbt.packager.docker._
dockerCommands := (dockerCommands.value.flatMap {
  case Cmd(_, args @ _*) if args.contains("1001") => None
  case cmd                       => Some(cmd)
}) ++ Seq(
  Cmd("RUN", "chmod +x bin/*"),
  Cmd("COPY", s"--from=$genomicToolRegistry/hmmer:3.1b2 /app/hmmer /app"),
  Cmd("COPY", s"--from=$genomicToolRegistry/hmm16s:1 /db/hmm16s /data")

)
dockerPermissionStrategy := DockerPermissionStrategy.None

enablePlugins(BuildInfoPlugin)
buildInfoKeys := Seq[BuildInfoKey](
  name,
  version,
  scalaVersion,
  sbtVersion,
  git.formattedShaVersion
)
buildInfoPackage := s"${organization.value}.info.${name.value.replace('-', '_')}"