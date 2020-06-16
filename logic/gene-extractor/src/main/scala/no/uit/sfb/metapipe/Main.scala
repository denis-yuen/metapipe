package no.uit.sfb.metapipe

import java.io.File

import no.uit.sfb.info.gene_extractor.BuildInfo
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
        head(
          "Extract each gene sequence, convert to protein domain, and build a FASTA file out of those genes"),
        head("Option to filter out non-complete genes"),
        opt[File]("contigsPath")
          .action((x, c) => c.copy(contigsPath = x.toPath))
          .required()
          .text(""),
        opt[File]("mgaOutPath")
          .action((x, c) => c.copy(mgaOutputPath = x.toPath))
          .required()
          .text("Path to MGA file"),
        opt[File]("outPath")
          .action((x, c) => c.copy(outPath = x.toPath))
          .required()
          .text("Path to write outputs to"),
        opt[Unit]("removeNonCompleteGenes")
          .action((x, c) => c.copy(removeNonCompleteGenes = true))
          .text("If set, filter out non-complete genes"),
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
