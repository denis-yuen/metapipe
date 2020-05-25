package no.uit.sfb.stages.egress

import java.nio.file.{Path, Paths}

import no.uit.sfb.apis.storage.ObjectId
import no.uit.sfb.s3store._
import no.uit.sfb.scalautils.common.{FileUtils, FutureUtils}

import scala.concurrent.{Await, ExecutionContext, Future}
import scala.concurrent.duration._
import scala.sys.process._

object Logic {
  implicit val ec = ExecutionContext.global

  def generateArchive(paths: Map[Path, ObjectId],
                      outputDir: Path,
                      cpu: Int): Unit = {
    paths foreach {
      case (from, to) =>
        val fromStr = from.toString
        assert(fromStr.count(_ == '*') <= 1,
               s"Only one '*' at most is allowed, but found more in '$fromStr'")
        val toStr = to.print
        assert(toStr.count(_ == '*') <= 1,
               s"Only one '*' at most is allowed, but found more in '$toStr'")
        val root =
          Paths.get(fromStr.split('*').head.split('/').init.mkString("/"))
        val files = FileUtils.filesUnder(root)
        val regexp = s"${fromStr.replace("*", "([^\\s/]*)")}".r
        val matchedFiles: Seq[(Path, String)] = files flatMap { f =>
          f.toString match {
            case regexp() =>
              Some(f -> "")
            case regexp(grp) =>
              Some(f -> grp)
            case _ =>
              None
          }
        }
        val filesAndTheirMapping = matchedFiles map {
          case (f, star) =>
            f -> toStr.replaceFirst("\\*", star)
        }
        val toAndFrom: Map[Path, Seq[Path]] =
          filesAndTheirMapping
            .groupBy { case (_, t) => outputDir.resolve(s"archive/$t") }
            .mapValues {
              _.map {
                _._1
              }
            }
        toAndFrom foreach {
          case (t, s) =>
            if (s.size == 1) {
              FileUtils.symLink(s.head, t)
            } else {
              FileUtils.createParentDirs(t)
              s"cat ${s.mkString(" ")}".#>(t.toFile).!!
            }
        }
    }
    s"tar -C ${outputDir.resolve("archive")} -hcvf - ." // --remove-files is not supported by all distrib
      .#|(s"pigz --best -p $cpu -c")
      .#>(outputDir.resolve("out.tgz").toFile)
      .!!
  }

  def exec(config: Config): Unit = {
    generateArchive(config.paths, config.outDir, config.cpu)

    val s3Store =
      MinioS3Client(
        config.url,
        config.access,
        config.secret
      )
    val f = Future {
      if (!s3Store.bucketExists(config.bucketName))
        s3Store.createBucket(config.bucketName)
    } map {
      _ =>
        s3Store.putObject(
          config.bucketName,
          config.location,
          config.outDir.resolve("out.tgz"),
          customMeta = Map(),
          downloadMeta = false
        )
    }
    val fr = FutureUtils.retry(f, 12, 5.minutes)
    Await.result(fr, 6.hours) //Might take a long time to upload data
  }
}
