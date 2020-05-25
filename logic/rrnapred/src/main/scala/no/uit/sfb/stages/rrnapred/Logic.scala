package no.uit.sfb.stages.rrnapred

import java.io.{BufferedWriter, FileOutputStream, OutputStreamWriter}
import java.nio.file.{Path, Paths}

import com.typesafe.scalalogging.LazyLogging
import no.uit.sfb.genomic.parser._
import no.uit.sfb.scalautils.common.{FileUtils, ParallelGZIPOutputStream, SystemProcess}

object Logic extends LazyLogging {
  def exec(config: Config): Unit = {
    val profiles: Seq[Path] = FileUtils
      .ls(config.hmmDir)
      ._2
      .filter(file => file.getFileName.toString.endsWith(".hmm")) //toString is important!

    def fastqToFasta(fq: FastqEntry): FastaEntry = {
      FastaEntry(fq.id, fq.sequence)
    }

    //Convert fastq to fasta and write to file using streams
    val fastaInput = Paths.get("/tmp/input.fasta")
    FastqRecord.aggregateFromFile(
      config.fastqPath,
      _.transform(
        fastqToFasta,
        new FastaWriter(
          new BufferedWriter(
            new OutputStreamWriter(new FileOutputStream(fastaInput.toFile))))))

    val hmmEntries: Map[String, HmmSearchDomainEntry] = {
      (profiles flatMap { profile =>
        val profileName = profile.getFileName
        val outPath = Paths.get(s"/tmp/out_$profileName.txt")
        SystemProcess(
          s"${config.hmmerPath} --domtblout $outPath --notextw --noali -E ${config.eValue} --cpu ${config.cpu} $profile $fastaInput")
          .exec(false)
        HmmSearchDomainRecord.fromFile(outPath) map { rec =>
          rec.targetName -> rec
        }
      }).toMap
    }

    FileUtils.createDirs(config.out)

    FastqRecord.aggregateFromFile(
      config.fastqPath,
      rri => {
        val fastaWriter = new FastaWriter(
          new BufferedWriter(new OutputStreamWriter(
            new FileOutputStream(config.out.resolve("pred16s.fasta").toFile))))
        val fastqWriter = new FastqWriter(
          new OutputStreamWriter(
            new ParallelGZIPOutputStream(new FileOutputStream(
              config.out.resolve("filtered.fastq.gz").toFile))))
        try {
          rri.foreach { fastqEntry =>
            hmmEntries.get(fastqEntry.id) match {
              case Some(hmmRec) =>
                val fasta =
                  FastaEntry(
                    fastqEntry.id,
                    fastqEntry.subSequence(hmmRec.envFrom, hmmRec.envTo))
                fastaWriter.writeEntry(fasta)
              case None => fastqWriter.writeEntry(fastqEntry)
            }
          }
        } finally {
          fastaWriter.close()
          fastqWriter.close()
        }
      }
    )
  }
}
