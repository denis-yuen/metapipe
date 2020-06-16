package no.uit.sfb.metapipe

import java.nio.file.Paths

import no.uit.sfb.scalautils.common.FileUtils
import org.scalatest.{FunSpec, Matchers}

class RoundRobinTest extends FunSpec with Matchers {
  describe("RoundRobinWriter") {
    val src =
      Paths
        .get(System.getProperty("user.dir"))
        .resolve("src/test/resources/sample.fasta")
    val outPath = Paths.get("target/roundRobin")
    FileUtils.deleteDirIfExists(outPath)
    val config =
      Config(src, outPath, contigsCutoff = 15, slices = 4)
    Logic.exec(config)
    it("should produce the correct output dirs") {
      val fasit = ((0 until 4) map { i =>
        outPath.resolve(s"$i")
      }).toSet
      FileUtils.ls(outPath)._1.toSet should be(fasit)
    }
    it("should yield right content") {
      FileUtils.readFile(outPath.resolve("0").resolve("contigs.fasta")) should be(
        """>0
          |GGCAGATTGGCAGATT
          |>4
          |GGCAGATTGGCAGATT
          |>9
          |GGCAGATTGGCAGATT
          |>14
          |GGCAGATTGGCAGATT
          |>18
          |GGCAGATTGGCAGATT""".stripMargin)
      FileUtils.readFile(outPath.resolve("1").resolve("contigs.fasta")) should be(
        """>1
          |GGCAGATTGGCAGATT
          |>6
          |GGCAGATTGGCAGATT
          |>10
          |GGCAGATTGGCAGATT
          |>15
          |GGCAGATTGGCAGATT""".stripMargin)
      FileUtils.readFile(outPath.resolve("2").resolve("contigs.fasta")) should be(
        """>2
          |GGCAGATTGGCAGATT
          |>7
          |GGCAGATTGGCAGATT
          |>11
          |GGCAGATTGGCAGATT
          |>16
          |GGCAGATTGGCAGATT""".stripMargin)
      FileUtils.readFile(outPath.resolve("3").resolve("contigs.fasta")) should be(
        """>3
          |GGCAGATTGGCAGATT
          |>8
          |GGCAGATTGGCAGATT
          |>13
          |GGCAGATTGGCAGATT
          |>17
          |GGCAGATTGGCAGATT""".stripMargin)
    }
  }
}
