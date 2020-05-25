import java.nio.file.{Path, Paths}

import com.typesafe.scalalogging.LazyLogging
import no.uit.sfb.metakube.wm.WorkflowManagerLike.{StageId, WorkflowId}
import no.uit.sfb.metakube.wm.impl.PachydermWorkflowManagerImpl
import no.uit.sfb.pachyderm.PachydermDriver
import no.uit.sfb.scalautils.common.SystemProcess
import org.scalatest.{FunSpec, Matchers}

import scala.concurrent.{Await, ExecutionContext}
import scala.concurrent.duration._
import scala.io.Source

class IntegrationTest extends FunSpec with Matchers with LazyLogging {
  implicit val ec = ExecutionContext.global

  var wid = ""
  val timeout = 2.minutes

  val minishiftProfile = sys.env("PROFILE")
  val ip = SystemProcess(s"minishift --profile $minishiftProfile ip").execFO(_.last)
    .getOrElse(throw new Exception(
      s"Minishift profile '$minishiftProfile' doesn't seem to exist. Please create it before running this test."))

  val pm = new PachydermWorkflowManagerImpl(new PachydermDriver(ip))

  def verifyLog(wid: WorkflowId,
                sid: StageId,
                prefix: String,
                expectedValue: String): Unit = {
    val logs =
      Await.result(pm.jobLogs(wid, sid) map { _.split("\n") }, timeout)
    assert(
      logs.filter { _.startsWith(prefix) }.exists(_.contains(expectedValue)),
      s"Could not find log line starting with '$prefix' and containing '$expectedValue'"
    )
  }

  /**
    * Check that the output file exists and it's size matches the expected size (if >= 0)
    * If exactMatch is false, the value must be in plus or minus 10% range.
    */
  def getFileSize(wid: WorkflowId, sid: StageId, path: Path): Long = {
    val outputs = Await.result(pm.listJobOutputs(wid, sid), timeout)
    val oFile = outputs.find { _.path == path }
    oFile match {
      case Some(out) => {
        out.size
      }
      case None => throw new AssertionError(s"Missing output file '$path'")
    }
  }
  def verifyOutputFileSizeSum(toolName: String = "",
                              expectedSize: Long = -1,
                              exactMatch: Boolean = true,
                              sizes: Seq[Long]): Unit = {
    val margin = 10 //in %
    val size = sizes.sum
    if (expectedSize >= 0) {
      if (exactMatch)
        assert(
          size == expectedSize,
          s"Wrong size for '$toolName', ($size was not equal to $expectedSize)")
      else
        assert(
          size >= expectedSize * (1 - margin / 100.0) && size <= expectedSize * (1 + margin / 100.0), //.0 is important
          s"Wrong size for '$toolName', ($size was not in +/-10% of $expectedSize)"
        )
    }

  }

  def verifyOutputFile(wid: WorkflowId,
                       sid: StageId,
                       path: Path,
                       expectedSize: Long = -1,
                       exactMatch: Boolean = true): Unit = {
    val margin = 10 //in %
    val outputs = Await.result(pm.listJobOutputs(wid, sid), timeout)
    val oFile = outputs.find { _.path == path }
    oFile match {
      case Some(out) =>
        val size = out.size
        if (expectedSize >= 0) {
          if (exactMatch)
            assert(
              size == expectedSize,
              s"Wrong size for '$path' ($size was not equal to $expectedSize)")
          else
            assert(
              size >= expectedSize * (1 - margin / 100.0) && size <= expectedSize * (1 + margin / 100.0), //.0 is important
              s"Wrong size for '$path' ($size was not in +/-10% of $expectedSize)"
            )
        }
      case None =>
        throw new AssertionError(s"Missing output file '$path'")
    }
  }

  //Must be lazy as otherwise the pachd may not yet be ready!
  lazy val sas = Await.result(pm.listActiveStages(), timeout)

  def findSid(startingWith: String): StageId = {
      sas.collectFirst {
        case as if as.id.startsWith(startingWith) => as.id
      }.get
    }

  val metakubeVersion = Source.fromFile("../../metakubeVersion").mkString

  describe("Fastq pathway") {
    it("should execute without failure") {
      SystemProcess(
        s"docker pull registry.gitlab.com/uit-sfb/metakube/mkadm:$metakubeVersion")
        .exec(false)
      wid = SystemProcess(
        s"""docker run --rm
           |--network host
           |-v ${Paths.get(System.getProperty("user.dir"))}/src/test/resources:/data/resources:ro
           |registry.gitlab.com/uit-sfb/metakube/mkadm:$metakubeVersion --
           |analysis submit --config /data/resources/job.yaml --pachd $ip:30650
           |illumina/forward=/data/resources/datasets/default_reads_fastq/R1_250000.fastq.gz,illumina/reverse=/data/resources/datasets/default_reads_fastq/R2_unordered.fastq.gz
           |""".stripMargin.replace("\n", " ")
      ).execF(_.last, true)
    }
    it("should have expected results for Seqprep") {
      val sid = findSid("assembly_seqprep")
      //verifyLog(wid, sid, "Pairs Processed", "62500")
      //verifyLog(wid, sid, "Pairs Merged", "54577")
      //verifyLog(wid, sid, "Pairs With Adapters", "4342")
      //verifyLog(wid, sid, "Pairs Discarded", "4")
      //verifyOutputFile(wid, sid, Paths.get("/data/r1.fastq.gz"), 1619477, false)
      //verifyOutputFile(wid, sid, Paths.get("/data/r2.fastq.gz"), 1791913, false)
      val r11 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r1/slices/0/unmerged_r1.fastq.gz"))
      val r12 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r1/slices/1/unmerged_r1.fastq.gz"))
      val r13 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r1/slices/2/unmerged_r1.fastq.gz"))
      val r14 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r1/slices/3/unmerged_r1.fastq.gz"))
      verifyOutputFileSizeSum("seqprep",
                              1612560,
                              false,
                              Seq(r11, r12, r13, r14))
      val r21 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r2/slices/0/unmerged_r2.fastq.gz"))
      val r22 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r2/slices/1/unmerged_r2.fastq.gz"))
      val r23 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r2/slices/2/unmerged_r2.fastq.gz"))
      val r24 = getFileSize(wid,
                            sid,
                            Paths.get("/data/r2/slices/3/unmerged_r2.fastq.gz"))
      verifyOutputFileSizeSum("seqprep",
                              1784571,
                              false,
                              Seq(r21, r22, r23, r24))
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/merged.fastq.gz"),
                       7108781,
                       false)
    }
    it("should have expected results for Trimmomatic SE") {
      val sid = findSid("assembly_trimmomaticSe")
      /*verifyLog(wid,
                sid,
                "Input Reads",
                "54577 Surviving: 51375 (94.13%) Dropped: 3202 (5.87%)")*/
      //verifyLog(wid, sid, "TrimmomaticSE", "Completed successfully")
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/merged.fastq.gz"),
                       6848200,
                       false)
    }
    it("should have expected results for Trimmomatic PE") {
      val sid = findSid("assembly_trimmomaticPe")
      /*verifyLog(
        wid,
        sid,
        "Input Read Pairs",
        "7919 Both Surviving: 5424 (68.49%) Forward Only Surviving: 1495 (18.88%) Reverse Only Surviving: 247 (3.12%) Dropped: 753 (9.51%)"
      )*/
      //verifyLog(wid, sid, "TrimmomaticPE", "Completed successfully")
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/unmerged_r1.fastq.gz"),
                       904850,
                       false)
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/unmerged_r2.fastq.gz"),
                       776027,
                       false)
    }
    it("should have expected results for Rrnapred") {
      val sid = findSid("assembly_rrnapred")
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/unmerged_r1/filtered.fastq.gz"),
                       900229,
                       false)
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/unmerged_r1/pred16s.fasta"),
                       26274,
                       false)
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/unmerged_r2/filtered.fastq.gz"),
                       773372,
                       false)
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/unmerged_r2/pred16s.fasta"),
                       20379,
                       false)
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/merged/filtered.fastq.gz"),
                       6816416,
                       false)
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/merged/pred16s.fasta"),
                       305187,
                       false)
    }
    it("should have expected results for Pairreads") {
      val sid = findSid("assembly_pairReads")
      verifyOutputFile(wid, sid, Paths.get("/data/r1.fastq.gz"), 884959, false)
      verifyOutputFile(wid, sid, Paths.get("/data/r2.fastq.gz"), 760021, false)
    }
    it("should have expected results for Megahit") {
      val sid = findSid("assembly_megahit")
      //mkDriver.verifyOutputFileSize(jobId, "/tmp/done", 0)
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/contigs.fasta"),
                       387811,
                       false)
    }
    //binning
    it("should have expected results for Binning bbwrap") {
      val sid = findSid("binning_bbwrap")
      verifyOutputFile(wid,
                       sid,
                       Paths.get("/data/alignment.sam.gz"),
                       2119185,
                       false)
    }
    it("should have expected results for Binning maxbin") {
      val sid = findSid("binning_maxbin")
      val out1 = getFileSize(wid, sid, Paths.get("/data/bin.001.fasta"))
      val out2 = getFileSize(wid, sid, Paths.get("/data/bin.002.fasta"))
      verifyOutputFileSizeSum("maxbin", 370156, false, Seq(out1, out2))
    }
    it("should have expected results for Binning pileup") {
      val sid = findSid("binning_bbpileup")
      verifyOutputFile(wid, sid, Paths.get("/data/coverage.txt"), 22369, false)
    }
    it("should have expected results for Binning bbsketch") {
      val sid = findSid("binning_bbsketch")
      val out1 = getFileSize(wid, sid, Paths.get("/data/bin.001.sketch"))
      val out2 = getFileSize(wid, sid, Paths.get("/data/bin.002.sketch"))
      verifyOutputFileSizeSum("bbsketch", 2372, false, Seq(out1, out2))
    }
    //functional analysis
    it("should have expected results for Diamond") {
      val sid = findSid("functionalAnalysis_diamond")
      val out1 = getFileSize(wid, sid, Paths.get("/data/slices/0/diamond.out"))
      val out2 = getFileSize(wid, sid, Paths.get("/data/slices/1/diamond.out"))
      val out3 = getFileSize(wid, sid, Paths.get("/data/slices/2/diamond.out"))
      val out4 = getFileSize(wid, sid, Paths.get("/data/slices/3/diamond.out"))
      verifyOutputFileSizeSum("diamond",
                              314458,
                              false,
                              Seq(out1, out2, out3, out4))
    }
    it("should have expected results for InterPro") {
      val sid = findSid("functionalAnalysis_interpro")
      val out1 = getFileSize(wid, sid, Paths.get("/data/slices/0/interpro.out"))
      val out2 = getFileSize(wid, sid, Paths.get("/data/slices/1/interpro.out"))
      val out3 = getFileSize(wid, sid, Paths.get("/data/slices/2/interpro.out"))
      val out4 = getFileSize(wid, sid, Paths.get("/data/slices/3/interpro.out"))
      verifyOutputFileSizeSum("interpro",
                              219603,
                              false,
                              Seq(out1, out2, out3, out4))
    }
    it("should have expected results for Mga") {
      val sid = findSid("functionalAnalysis_mga")
      val out1 = getFileSize(wid, sid, Paths.get("/data/slices/0/mga.out"))
      val out2 = getFileSize(wid, sid, Paths.get("/data/slices/1/mga.out"))
      val out3 = getFileSize(wid, sid, Paths.get("/data/slices/2/mga.out"))
      val out4 = getFileSize(wid, sid, Paths.get("/data/slices/3/mga.out"))
      verifyOutputFileSizeSum("mga", 44617, false, Seq(out1, out2, out3, out4))
    }
    it("should have expected results for Contigssplitter") {
      val sid = findSid("functionalAnalysis_preProcessContigs")
      val out1 =
        getFileSize(wid, sid, Paths.get("/data/slices/0/contigs.fasta"))
      val out2 =
        getFileSize(wid, sid, Paths.get("/data/slices/1/contigs.fasta"))
      val out3 =
        getFileSize(wid, sid, Paths.get("/data/slices/2/contigs.fasta"))
      val out4 =
        getFileSize(wid, sid, Paths.get("/data/slices/3/contigs.fasta"))
      verifyOutputFileSizeSum("contigssplitter",
                              392715,
                              false,
                              Seq(out1, out2, out3, out4))
    }
    it("should have expected results for postProcessingMga") {
      val sid = findSid("functionalAnalysis_postProcessingMga")
      //proteins
      val outProt1 =
        getFileSize(wid, sid, Paths.get("/data/slices/0/cds.prot.fasta"))
      val outProt2 =
        getFileSize(wid, sid, Paths.get("/data/slices/1/cds.prot.fasta"))
      val outProt3 =
        getFileSize(wid, sid, Paths.get("/data/slices/2/cds.prot.fasta"))
      val outProt4 =
        getFileSize(wid, sid, Paths.get("/data/slices/3/cds.prot.fasta"))
      verifyOutputFileSizeSum("postProcessingMga",
                              119025,
                              false,
                              Seq(outProt1, outProt2, outProt3, outProt4))
    }
    it("should have expected results for Priam") {
      val sid = findSid("functionalAnalysis_priam")
      //Result 0
      val out01 =
        getFileSize(wid, sid, Paths.get("/data/slices/0/genomeECs.txt"))
      val out02 =
        getFileSize(wid, sid, Paths.get("/data/slices/0/genomeEnzymes.txt"))
      val out03 =
        getFileSize(wid, sid, Paths.get("/data/slices/0/predictableECs.txt"))
      val out04 =
        getFileSize(wid, sid, Paths.get("/data/slices/0/sequenceECs.txt"))
      //Result 1
      val out11 =
        getFileSize(wid, sid, Paths.get("/data/slices/1/genomeECs.txt"))
      val out12 =
        getFileSize(wid, sid, Paths.get("/data/slices/1/genomeEnzymes.txt"))
      val out13 =
        getFileSize(wid, sid, Paths.get("/data/slices/1/predictableECs.txt"))
      val out14 =
        getFileSize(wid, sid, Paths.get("/data/slices/1/sequenceECs.txt"))
      //Result 2
      val out21 =
        getFileSize(wid, sid, Paths.get("/data/slices/2/genomeECs.txt"))
      val out22 =
        getFileSize(wid, sid, Paths.get("/data/slices/2/genomeEnzymes.txt"))
      val out23 =
        getFileSize(wid, sid, Paths.get("/data/slices/2/predictableECs.txt"))
      val out24 =
        getFileSize(wid, sid, Paths.get("/data/slices/2/sequenceECs.txt"))
      verifyOutputFileSizeSum("priam",
                              331896,
                              false,
                              Seq(out01,
                                  out02,
                                  out03,
                                  out04,
                                  out11,
                                  out12,
                                  out13,
                                  out14,
                                  out21,
                                  out22,
                                  out23,
                                  out24))
    }
    it("should have expected results for Kaiju") {
      val sid = findSid("taxonomy_kaiju")
      verifyOutputFile(wid, sid, Paths.get("/data/kaiju.out"), 3077293, false) //with mardb
    }
    it("should have expected results for Mapseq") {
      val sid = findSid("taxonomy_mapseq")
      verifyOutputFile(wid, sid, Paths.get("/data/mapseq.out"), 235055, false) //with silvamar
    }
  }
}
