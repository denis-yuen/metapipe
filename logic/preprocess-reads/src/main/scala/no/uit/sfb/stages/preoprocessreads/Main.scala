package no.uit.sfb.stages.preoprocessreads

import java.io.File

import no.uit.sfb.info.metapipe_preprocess_reads.BuildInfo
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
        head("De-interleave interleavedd FASTQ file (if applicable)"),
        head(
          "Discard any sequence smaller than the provided --cutoff (if applicable)"),
        head("Split the output files in --slices slices"),
        opt[File]("interleaved")
          .action((x, c) => c.copy(r1OrInterleavedPath = x.toPath))
          .text("Path to Fastq file (interleaved reads). May be gzipped."),
        opt[File]("r1")
          .action((x, c) => c.copy(r1OrInterleavedPath = x.toPath))
          .text("Path to R1 Fastq file. May be gzipped."),
        opt[File]("r2")
          .action((x, c) => c.copy(r2Path = x.toPath))
          .text("Path to R2 Fastq file. May be gzipped."),
        opt[File]("outputDir")
          .action((x, c) => c.copy(outputPath = x.toPath))
          .text("Path to output dir"),
        opt[File]("tmpDir")
          .action((x, c) => c.copy(tmpPath = x.toPath))
          .text("Path to tmp dir"),
        opt[Int]("slices")
          .action(
            (x, c) =>
              if (x <= 0)
                c.copy(slices = 1, noSlicing = true)
              else
                c.copy(slices = x, noSlicing = false))
          .text("Number of slices to split the read files into (default: 1)")
          .text(
            "Setting this field to 0 is equivalent to 1 slice but the output is written to the output dir instead of outputDir/0"),
        help("help")
          .text("Prints this usage text"),
        version('v', "version")
      )
    }

    val check = {
      import builder._
      OParser.sequence(
        checkConfig(
          c =>
            if (c.r1OrInterleavedPath == null)
              failure("interleaved or r1 file path must be provided")
            else if (c.r2Path != null && c.tmpPath == null)
              failure("tmpDir must be provided if r2 provided")
            else
            success)
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
