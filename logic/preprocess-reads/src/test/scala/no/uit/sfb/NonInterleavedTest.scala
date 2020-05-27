package no.uit.sfb

import java.nio.file.Paths

import no.uit.sfb.scalautils.common.FileUtils
import no.uit.sfb.metapipe.preoprocessreads.{Config, Logic}
import org.scalatest.{FunSpec, Matchers}

class NonInterleavedTest extends FunSpec with Matchers {
  describe("Non-interleaved") {
    val testDir =
      Paths
        .get(System.getProperty("user.dir"))
        .resolve("target/test/nonInterleaved")
    val tmpDir = testDir.resolve("tmp")
    val resDir = testDir.resolve("res")
    FileUtils.deleteDirIfExists(tmpDir)
    FileUtils.createDirs(testDir)
    val config = Config(
      r1OrInterleavedPath = Paths
        .get(System.getProperty("user.dir"))
        .resolve("src/test/resources/r1.fastq"),
      r2Path = Paths
        .get(System.getProperty("user.dir"))
        .resolve("src/test/resources/r2.fastq"),
      outputPath = resDir,
      tmpPath = tmpDir,
      slices = 3
    )

    it("should execute without failure") {
      Logic.exec(config)
    }
    it("should generate the desired files") {
      val fasit = Set(
        resDir.resolve("0/r1.fastq.gz"),
        resDir.resolve("1/r1.fastq.gz"),
        resDir.resolve("2/r1.fastq.gz"),
        resDir.resolve("0/r2.fastq.gz"),
        resDir.resolve("1/r2.fastq.gz"),
        resDir.resolve("2/r2.fastq.gz")
      )
      FileUtils.filesUnder(resDir).toSet should be(fasit)
      fasit forall { path =>
        FileUtils.size(path) > 0
      } should be(true)
    }
  }
}
