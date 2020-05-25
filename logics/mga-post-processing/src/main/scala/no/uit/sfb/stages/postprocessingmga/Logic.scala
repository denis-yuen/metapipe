package no.uit.sfb.stages.postprocessingmga

import java.io.{
  BufferedInputStream,
  BufferedReader,
  BufferedWriter,
  FileInputStream,
  FileOutputStream,
  InputStreamReader,
  OutputStreamWriter
}
import java.nio.file.Path

import no.uit.sfb.genomic.model._
import no.uit.sfb.genomic.parser._
import no.uit.sfb.scalautils.common.FileUtils
import no.uit.sfb.scalautils.common.record.rw.RecordReaderIterator
import org.biojava.bio.seq.{DNATools, RNATools}

object Logic {

  /**
    * Note: This implementation is lazy since Iterator are lazy.
    *
    * # k141_271594 flag=1 multi=2.8558 len=2624
    * # gc = 0.53125, rbs = -1
    * # self: -
    * gene_1  108     536     +       0       11      17.9819 a       92      97      -2.40141
    * gene_2  599     862     -       0       11      18.6806 a       -       -       -
    * gene_3  893     1684    -       0       11      14.9561 a       -       -       -
    * gene_4  2221    2624    -       2       01      39.3623 a       -       -       -
    *
    * geneNb  a       b       strand  frame   pq
    * if strand == + -> from left to right -> a == start, b == end
    * if strand == - -> from right to left -> a == end, b == start
    * if p == 1, start non-truncated, if p == 0 start truncated
    * if q == 1, end non-truncated, if q == 0 start truncated
    * NOTE: the frame is NOT a frame in the biological therm. It is the "non-translated surplus at the start". So In the case above we need to make the gene start at 2622.
    */
  def exec(config: Config): Unit = {
    val nucOutPath = config.outPath.resolve("cds.nuc.fasta")
    val nucProtPath = config.outPath.resolve("cds.prot.fasta")
    def writeToFile(path: Path,
                    fastaIt: Iterator[FastaEntry],
                    convert: FastaEntry => FastaEntry) {
      FileUtils.createParentDirs(path)
      val writer = new FastaWriter(
        new BufferedWriter(
          new OutputStreamWriter(new FileOutputStream(path.toFile))))
      try {
        fastaIt foreach { entry =>
          writer.writeEntry(convert(entry))
        }
      } finally {
        writer.close()
      }
    }

    MgaRecord.aggregateFromFile(
      config.mgaOutputPath,
      rri => {
        //We optionally filter out non-complete genes
        val filteredMga = if (config.removeNonCompleteGenes) {
          rri.map { annotation =>
            annotation.copy(
              predictedGenes =
                annotation.predictedGenes.filter(_.completePartial == "11"))
          }
        } else
          rri

        //We dress a list of all the genes present and extract the sequence (properly ordered and reverse-complemented in case of negative strand), paying attention to the start frame of the gene.
        val fastaReads = new RecordReaderIterator[FastaEntry](
          new FastaReader(
            new BufferedReader(
              new InputStreamReader(
                FileUtils.unGzipStream(new BufferedInputStream(
                  new FileInputStream(config.contigsPath.toFile)))))))
        val predictedGenesNuc: Iterator[FastaEntry] =
          (filteredMga zip fastaReads) //This is right even with filtering out non-complete genes since it removes genes from MgaEntries, but do not remove any MgaEntry. So mga.in remains in sync with mga.out
            .flatMap {
              case (mgaAnnotation, fasta) =>
                mgaAnnotation.predictedGenes.map {
                  gene =>
                    val geneId =
                      s"${mgaAnnotation.id.value}_${gene.geneDenomination}"
                    val rawLocation =
                      Location(gene.startPos, gene.endPos, Strand(gene.strand))
                    //We correct the frame (discard as many letters at the starting end as given by 'frame')
                    val locationWithFrameCorrection =
                      rawLocation match {
                        case Location(start, stop, Positive) => //Unlike an array, the first location is 1
                          val newStart = start + gene.frame //We trim out the surplus
                          val length = stop - newStart + 1
                          val newStop = stop - (length % 3) //We correct the end so that the length is a multiple of 3
                          Location(newStart, newStop, Positive)
                        case Location(start, stop, Negative) =>
                          val newStop = stop - gene.frame //We trim out the surplus
                          val length = newStop - start + 1
                          val newStart = start + (length % 3) //We correct the start so that the length is a multiple of 3
                          Location(newStart, newStop, Negative)
                      }
                    //We trim out the sequence
                    FastaEntry(
                      geneId,
                      fasta.subSequence(locationWithFrameCorrection)
                    )
                }
            }
        writeToFile(nucOutPath, predictedGenesNuc, identity)
      }
    )

    def nucToProt(fastaEntry: FastaEntry): FastaEntry = {
      val dna = DNATools.createDNA(fastaEntry.sequence)
      val rna = DNATools.toRNA(dna)
      val protStr = RNATools.translate(rna).seqString()
      val protStrWithoutEndStar =
        if (protStr.last == '*')
          protStr.dropRight(1)
        else
          protStr
      fastaEntry.copy(sequence = protStrWithoutEndStar)
    }

    //Very quick
    FastaRecord.aggregateFromFile(nucOutPath, rri => {
      writeToFile(nucProtPath, rri, nucToProt)
    })
  }
}
