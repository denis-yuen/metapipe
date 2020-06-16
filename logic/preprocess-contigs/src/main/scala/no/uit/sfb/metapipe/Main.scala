package no.uit.sfb.metapipe

import java.io.File

import scopt.OParser
import no.uit.sfb.info.preprocess_contigs.BuildInfo

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
        opt[File]("inputPath")
          .action((x, c) => c.copy(inputPath = x.toPath))
          .required()
          .text("Input path"),
        opt[File]("outPath")
          .action((x, c) => c.copy(outPath = x.toPath))
          .text("Directory output path"),
        opt[Int]("contigsCutoff")
          .action((x, c) => c.copy(contigsCutoff = x))
          .required()
          .text("Contigs cutoff"),
        opt[Int]("slices")
          .action((x, c) => c.copy(slices = x))
          .valueName("Number of slices to cut the input into")
          .required(),
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
