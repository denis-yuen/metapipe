package no.uit.sfb

import java.nio.file.Paths

import no.uit.sfb.scalautils.common.FileUtils
import no.uit.sfb.metapipe.preoprocessreads.{Config, Logic}
import org.scalatest.{FunSpec, Matchers}

class InterleavedTest extends FunSpec with Matchers {
  describe("Interleaved") {
    val testDir =
      Paths
        .get(System.getProperty("user.dir"))
        .resolve("target/test/interleaved")
    val tmpDir = testDir.resolve("tmp")
    FileUtils.deleteDirIfExists(tmpDir)
    FileUtils.createDirs(testDir)
    val config = Config(
      r1OrInterleavedPath = Paths
        .get(System.getProperty("user.dir"))
        .resolve("src/test/resources/interleaved.fastq"),
      outputPath = testDir,
      tmpPath = tmpDir,
      slices = 3
    )

    it("should execute without failure") {
      Logic.exec(config)
    }
    it("should generate the desired files") {
      val fasit = Set(
        testDir.resolve("0/r1.fastq.gz"),
        testDir.resolve("1/r1.fastq.gz"),
        testDir.resolve("2/r1.fastq.gz"),
        testDir.resolve("0/r2.fastq.gz"),
        testDir.resolve("1/r2.fastq.gz"),
        testDir.resolve("2/r2.fastq.gz")
      )
      FileUtils.filesUnder(testDir).toSet should be(fasit)
      fasit forall { path =>
        FileUtils.size(path) > 0
      } should be(true)
    }
  }
}
