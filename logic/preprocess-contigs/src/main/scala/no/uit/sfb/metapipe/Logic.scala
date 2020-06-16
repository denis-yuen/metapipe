package no.uit.sfb.metapipe

import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}

import no.uit.sfb.genomic.parser._
import no.uit.sfb.scalautils.common.{FileUtils, RoundRobinWriter}

object Logic {
  def exec(config: Config): Unit = {
    val fileName = "contigs.fasta"
    val outPath = config.outPath
    val outFiles = (0 until config.slices).map { i =>
      val filePath = outPath.resolve(s"$i/$fileName")
      FileUtils.createParentDirs(filePath)
      filePath
    }
    val fairWriter: no.uit.sfb.genomic.parser.FastaWriter = {
      val writers = outFiles.map { filePath =>
        new BufferedWriter(
          new OutputStreamWriter(new FileOutputStream(filePath.toFile)))
      }
      new RoundRobinFastaWriter(new RoundRobinWriter(writers))
    }

    FastaRecord.aggregateFromFile(
      config.inputPath,
      _.transformAndFilter(
        { fe: FastaEntry =>
          if (fe.sequenceLength >= config.contigsCutoff)
            Some(fe)
          else
            None
        },
        fairWriter
      )
    )

    //We delete any empty output file
    outFiles foreach { f =>
      if (FileUtils.size(f) == 0)
        FileUtils.deleteDir(f.getParent)
    }
  }
}
