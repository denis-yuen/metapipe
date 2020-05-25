package no.uit.sfb.databases.utils

import java.nio.file.Paths

import no.uit.sfb.scalautils.common.FileUtils

import scala.util.Try

object ArtifactCreds {
  private lazy val sbtCreds =
    Paths.get(sys.env("HOME")).resolve(".sbt").resolve(".credentials")

  lazy val user: Option[String] = Try {
    FileUtils.readFile(sbtCreds)
  }.toOption flatMap { str =>
    //str.lines doesn't work in java 11 because of a conflict. Use linesIterator instead.
    str.linesIterator.filter { _.contains("user=") }.toSeq.headOption.map { l =>
      l.takeRight(l.length - 5)
    }
  }

  lazy val password: Option[String] = Try {
    FileUtils.readFile(sbtCreds)
  }.toOption flatMap { str =>
    //str.lines doesn't work in java 11 because of a conflict. Use linesIterator instead.
    str.linesIterator.filter { _.contains("password=") }.toSeq.headOption.map { l =>
      l.takeRight(l.length - 9)
    }
  }
}
