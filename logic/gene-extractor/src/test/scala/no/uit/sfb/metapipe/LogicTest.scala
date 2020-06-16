package no.uit.sfb.metapipe

import java.nio.file.Paths

import no.uit.sfb.scalautils.common.FileUtils
import no.uit.sfb.metapipe.{Config, Logic}
import org.scalatest.{FunSpec, Matchers}

class LogicTest extends FunSpec with Matchers {
  val resourcesPath = Paths.get(
    s"${Paths.get(System.getProperty("user.dir"))}/src/test/resources")
  describe("Logic") {
    it("should properly trim incomplete genes") {
      val targetPath = Paths.get("target/test")
      FileUtils.createDirs(targetPath)
      val cfg = Config(
        contigsPath = resourcesPath.resolve("truncated_starts/contigs.fasta"),
        mgaOutputPath = resourcesPath.resolve("truncated_starts/mga.out"),
        outPath = targetPath,
        removeNonCompleteGenes = false
      )
      Logic.exec(cfg)
    }
  }
}
