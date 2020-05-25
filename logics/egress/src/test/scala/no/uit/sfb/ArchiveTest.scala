package no.uit.sfb

import java.nio.file.Paths

import no.uit.sfb.apis.storage.ObjectId
import no.uit.sfb.scalautils.common.FileUtils
import no.uit.sfb.stages.egress.Logic
import org.scalatest.{FunSpec, Matchers}

class ArchiveTest extends FunSpec with Matchers {
  describe("generateArchive") {
    val resources =
      Paths
        .get(System.getProperty("user.dir"))
        .resolve("src/test/resources")
    val outPath = Paths.get("target/test")
    FileUtils.deleteDirIfExists(outPath)

    val paths = Map(
      resources.resolve("pfs/assembly_megahit/contigs.fasta") -> ObjectId
        .fromString("assembly/contigs.fasta"),
      resources
        .resolve("pfs/taxonomy_kaiju/kaiju.out") -> ObjectId
        .fromString("taxonomy/kaiju.out"),
      resources
        .resolve("pfs/taxonomy_mapseq/mapseq.out") -> ObjectId
        .fromString("taxonomy/mapseq.out"),
      resources
        .resolve("pfs/binning_bbsketch/bin.*.sketch") -> ObjectId
        .fromString("binning/bin.*.sketch"),
      resources
        .resolve("pfs/functionalAnalysis_priam/slices/*/genomeECs.txt") -> ObjectId
        .fromString("functionalAnalysis/priam/genomeECs.txt"),
    )
    it("should produce the correct archive") {
      Logic.generateArchive(paths, outPath, 4)
      FileUtils.size(outPath.resolve("out.tgz")) / 100 should be(3) // /100 to have some free room
    }
  }
}
