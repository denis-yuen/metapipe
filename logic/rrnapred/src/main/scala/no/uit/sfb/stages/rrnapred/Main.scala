package no.uit.sfb.stages.rrnapred

import java.io.File

import no.uit.sfb.info.metapipe_rrnapred.BuildInfo
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
        opt[File]('i', "input")
          .action((x, c) => c.copy(fastqPath = x.toPath))
          .required()
          .text("Path to Fastq input file"),
        opt[File]("hmm")
          .action((x, c) => c.copy(hmmDir = x.toPath))
          .text("Path to directory containing profiles (.hmm)"),
        opt[File]("out")
          .action((x, c) => c.copy(out = x.toPath))
          .required()
          .text("Path to output directory"),
        opt[File]("hmmsearch")
          .action((x, c) => c.copy(hmmerPath = x.toPath))
          .text("Path to hmmsearch executable"),
        opt[Double]('E', "evalue")
          .action((x, c) => c.copy(eValue = x))
          .text("e Value"),
        opt[Int]("cpu")
          .action((x, c) => c.copy(cpu = x))
          .text("Number of CPUs"),
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
