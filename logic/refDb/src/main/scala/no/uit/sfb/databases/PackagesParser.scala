package no.uit.sfb.databases

import java.io.File

import scopt.OParser
import no.uit.sfb.info.ref_databases_mgmt.BuildInfo

object PackagesParser {

  val name = BuildInfo.name
  val ver = BuildInfo.version
  val gitCommitId = BuildInfo.formattedShaVersion

  lazy val builder = OParser.builder[PackagesConfig]

  lazy val parser = {
    import builder._
    OParser.sequence(
      programName(name),
      head(name, ver),
      head(s"git: ${gitCommitId.getOrElse("unknown")}"),
      help('h', "help")
        .text("prints this usage text"),
      cmd("list")
        .action((_, c) => c.copy(cmd = "list"))
        .text("list all packages available on metapipe's artifact store"),
      cmd("latest")
        .children(
          arg[String]("package")
            .action((x, c) => c.copy(packageName = x))
            .text(
              "package name (without version)"
            )
        )
        .action((_, c) => c.copy(cmd = "latest"))
        .text("returns the latest package available on metapipe's artifact store matching the provided package name"),
      cmd("download")
        .action((_, c) => c.copy(cmd = "download"))
        .text("download packages available on metapipe's artifact store")
        .children(
          opt[Unit]('w', "overwrite")
            .action((x, c) => c.copy(overwrite = true))
            .text("overwrite existing packages"),
          opt[Unit]('f', "force")
            .action((x, c) => c.copy(force = true))
            .text(
              "force download: in case a lock is taken, remove the lock and matching directory. Do NOT use in multi-thread environments!"),
          opt[Unit]('c', "cleanup")
            .action((x, c) => c.copy(cleanup = true))
            .text("remove older versions"),
          opt[File]('d', "dir")
            .action((x, c) => c.copy(dir = x.toPath.toAbsolutePath))
            .text("target directory"),
          arg[Seq[String]]("packages")
            .action((x, c) => c.copy(packages = x.toSet))
            .text(
              """list of packages to download with the following format: <package1> <package2=<version> ...
                |When version is not defined, the highest version available is used.
              """.stripMargin
            )
        ),
      cmd("download-all")
        .action((_, c) => c.copy(cmd = "download-all"))
        .text("download packages available on metapipe's artifact store.")
        .children(
          opt[Unit]('w', "overwrite")
            .action((x, c) => c.copy(overwrite = true))
            .text("overwrite existing packages"),
          opt[Unit]('f', "force")
            .action((x, c) => c.copy(force = true))
            .text(
              "force download: in case a lock is taken, remove the lock and matching directory. Do NOT use in multi-thread environments!"),
          opt[Unit]('c', "cleanup")
            .action((x, c) => c.copy(cleanup = true))
            .text("remove older versions"),
          opt[File]('d', "dir")
            .action((x, c) => c.copy(dir = x.toPath.toAbsolutePath))
            .text("target directory")
        ),
      cmd("create")
        .action((_, c) => c.copy(cmd = "create"))
        .text("create artifact for the given image.")
        .children(
          opt[Unit]('w', "overwrite")
            .action((x, c) => c.copy(overwrite = true))
            .text("overwrite existing packages"),
          opt[File]('d', "dir")
            .action((x, c) => c.copy(dir = x.toPath.toAbsolutePath))
            .text("target directory"),
          opt[String]('u', "user")
            .action((x, c) => c.copy(artifactoryUser = Some(x)))
            .text("Artifactory user"),
          opt[String]('p', "password")
            .action((x, c) => c.copy(artifactoryPassword = Some(x)))
            .text("Artifactory password"),
          arg[String]("image")
            .action((x, c) => c.copy(imageName = x))
            .text(
              "docker image to convert to artifact"
            )
        )
    )
  }
}
