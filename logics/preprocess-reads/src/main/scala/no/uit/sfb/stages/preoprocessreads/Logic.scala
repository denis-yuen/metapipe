package no.uit.sfb.stages.preoprocessreads

import java.io.{BufferedOutputStream, FileOutputStream, OutputStreamWriter}
import java.nio.file.Path

import no.uit.sfb.genomic.parser.{
  FastqEntry,
  FastqRecord,
  FastqWriter,
  HashRobinFastqWriter,
  RoundRobinFastqWriter
}
import no.uit.sfb.scalautils.common.{
  FileUtils,
  HashRobinWriter,
  ParallelGZIPOutputStream,
  RoundRobinWriter
}
import no.uit.sfb.scalautils.common.record.rw.RecordReaderIterator

import scala.collection.parallel.ParIterable
import scala.collection.{immutable, mutable}

/*
RAM: O(1) if interleaved
RAM: O(n/(2)) if not interleaved.
Note: n refers to the UN-GZIPPED size
 */
object Logic {
  def exec(config: Config): Unit = {
    import no.uit.sfb.genomic.parser.Records._

    def writeAll(filePath: Path, writer: FastqWriter): Unit = {
      val usage: RecordReaderIterator[FastqEntry] => Unit = rri => {
        rri.foreach { writer.writeEntry }
      }
      try {
        FastqRecord.aggregateFromFile[Unit](filePath, usage)
      } finally {
        writer.close()
      }
    }

    if (config.r2Path != null) {
      //Not interleaved input

      val microSlices: Int = {
        val rawSlices = FileUtils.size(config.r1OrInterleavedPath) / (4 * 1024 * 1024)
        val cnt = rawSlices - (rawSlices % config.slices) //We ensure the number of slices is a multiple of config.slices
        if (cnt < config.slices)
          config.slices
        else cnt.toInt
      }
      val numCores = Runtime.getRuntime().availableProcessors()

      println(s"Using $microSlices microslices")
      println(s"Using $numCores threads")

      val bufferSize = 65536

      println(
        s"The memory impact will be at least ${2 * bufferSize * microSlices / (1024 * 1024)} MiB.")

      //Returns a duo of HashRobinFastqWriters (i.e. 2*slices writers)
      lazy val tmpWriterDuo: Seq[FastqWriter] = {
        for { ri <- Seq(1, 2) } yield {
          val writers = (0 until microSlices).map { microSliceId =>
            val filePath = config.tmpPath.resolve(s"$microSliceId/r$ri.fastq")
            FileUtils.createParentDirs(filePath)
            new OutputStreamWriter(
              new BufferedOutputStream(new FileOutputStream(filePath.toFile),
                                       bufferSize)
            )
          }
          new HashRobinFastqWriter(new HashRobinWriter(writers))
        }
      }

      lazy val finalWriterDuo: (Array[FastqWriter], Array[FastqWriter]) = {
        val parallelism = {
          val tmp = numCores / config.slices
          if (tmp <= 0) 1 else tmp
        }
        val seq = Seq(1, 2) map { ri =>
          (0 until config.slices) map { i =>
            val file =
              if (config.noSlicing)
                config.outputPath.resolve(s"r$ri.fastq.gz")
              else
                config.outputPath.resolve(s"$i").resolve(s"r$ri.fastq.gz")
            FileUtils.createParentDirs(file)
            new FastqWriter(
              new OutputStreamWriter(
                new ParallelGZIPOutputStream(
                  new FileOutputStream(file.toFile),
                  parallelism))) //Since we are already executing in parallel, we cannot use numCores here otherwise it would be over-parallelizing
          }
        }
        seq.head.toArray -> seq.last.toArray
      }

      //Order r2 following r1's order. Items present in only one file are discarded
      def pair(r1: Path,
               r2: Path,
               r1Writer: FastqWriter,
               r2Writer: FastqWriter): Unit = {
        val r2TreeMap = {
          val _r2TreeMap = mutable.TreeMap[String, FastqEntry]()
          val usage: RecordReaderIterator[FastqEntry] => Unit = rri => {
            rri.foreach { entry =>
              _r2TreeMap += (entry.id -> entry)
            }
          }
          FastqRecord.aggregateFromFile[Unit](r2, usage)
          _r2TreeMap
        }
        val usage: RecordReaderIterator[FastqEntry] => Unit = rri => {
          rri.foreach { r1Entry =>
            r2TreeMap.get(r1Entry.id) match {
              case Some(r2Entry) =>
                r1Writer.writeEntry(r1Entry)
                r2Writer.writeEntry(r2Entry)
              case _ => //Do nothing
            }
          }
        }
        FastqRecord.aggregateFromFile[Unit](r1, usage)
        //Do not close the writers here! They might still be used for another micro-slice!
      }

      //First, we split the two input files and write the slices to tmp
      val inpFiles = Seq(config.r1OrInterleavedPath, config.r2Path)
      (inpFiles zip tmpWriterDuo).par foreach {
        case (filePath, hashWriter) =>
          writeAll(filePath, hashWriter)
      }
      //We pair each slices and write them to the output location
      val k
        : Map[Int, immutable.IndexedSeq[Int]] = (0 until microSlices) groupBy {
        _ % config.slices
      }
      //By using groupBy a second time we ensure that the same file will not be written into by two parallel tranches
      val l: ParIterable[Map[Int, immutable.IndexedSeq[Int]]] =
        (k groupBy { _._1 % numCores }).values.par
      try {
        l foreach { it =>
          it foreach {
            case (sliceId, microSlices) =>
              microSlices foreach { microSliceId =>
                pair(
                  config.tmpPath.resolve(s"$microSliceId/r1.fastq"),
                  config.tmpPath
                    .resolve(s"$microSliceId/r2.fastq"),
                  finalWriterDuo._1(sliceId),
                  finalWriterDuo._2(sliceId)
                )
              }
          }
        }
      } finally {
        finalWriterDuo._1 foreach { _.close() }
        finalWriterDuo._2 foreach { _.close() }
      }
    } else {
      //Interleaved input
      val writers = for {
        i <- 0 until config.slices
        ri <- Seq(1, 2)
      } yield {
        val filePath =
          if (config.noSlicing)
            config.outputPath.resolve(s"r$ri.fastq.gz")
          else
            config.outputPath.resolve(s"$i").resolve(s"r$ri.fastq.gz")
        FileUtils.createParentDirs(filePath)
        new OutputStreamWriter(
          new ParallelGZIPOutputStream(new FileOutputStream(filePath.toFile))
        )
      }
      val writer = new RoundRobinFastqWriter(new RoundRobinWriter(writers))
      writeAll(config.r1OrInterleavedPath, writer)
    }
  }
}
