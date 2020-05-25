package no.uit.sfb.stages.egress

import java.io.File
import java.net.URL
import java.nio.file.Paths

import no.uit.sfb.info.metapipe_egress.BuildInfo
import no.uit.sfb.apis.storage._
import scopt.OParser

object Main extends App {
  try {
    val builder = OParser.builder[Config]

    val name = BuildInfo.name
    val ver = BuildInfo.version
    val gitCommitId = BuildInfo.formattedShaVersion

    val parser = {
      import builder._
      OParser.sequence(
        programName(name),
        head(name, ver),
        head(s"git: ${gitCommitId.getOrElse("unknown")}"),
        opt[URL]("url")
          .required()
          .action((x, c) => c.copy(url = x))
          .text("S3 URL"),
        opt[String]("bucket")
          .required()
          .action((x, c) => c.copy(bucketName = x))
          .text("S3 bucket"),
        opt[String]("access-key")
          .action((x, c) => c.copy(access = x))
          .text("S3 access key"),
        opt[String]("secret-key")
          .action((x, c) => c.copy(secret = x))
          .text("S3 secret key"),
        opt[String]("location")
          .action((x, c) => c.copy(location = ObjectId.fromString(x)))
          .text("Path in bucket"),
        opt[Int]("cpu")
          .action((x, c) => c.copy(cpu = x))
          .text("Number of CPUs available for pigz"),
        opt[File]("outdir")
          .required
          .action((x, c) => c.copy(outDir = x.toPath))
          .text("Output directory"),
        arg[String]("paths")
          .valueName("<from1=to1> <from2=to2>...")
          .unbounded()
          .action((x, c) =>
            c.copy(paths = {
              val split = x.split('=')
              c.paths + (Paths.get(split.head) -> ObjectId.fromString(split.tail.mkString("=")))
            }))
          .text("Paths couples (from/to), 'to' being the path in the archive.")
          .text("* is allowed in both from/to and files having the same 'to' are concatenated by lexicographic order of their 'from'.")
          .text("Only one '*' may be used per entry and it cannot cross a '/' boundary."),
        help("help")
          .text("Prints this usage text"),
        version('v', "version")
      )
    }

    val check = {
      import builder._
      OParser.sequence(
        checkConfig(c => success)
      )
    }

    OParser.parse(parser ++ check, args, Config()) match {
      case Some(config) =>
        Logic.exec(config)
      case _ =>
        // arguments are bad, error message will have been displayed
        throw new IllegalArgumentException()
    }
  } catch {
    case e: Throwable =>
      println(e.toString)
      println(e.printStackTrace())
      sys.exit(1)
  }
}
