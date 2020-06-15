package no.uit.sfb.databases

import java.net.URL
import java.nio.file._

import com.typesafe.scalalogging.LazyLogging
import no.uit.sfb.databases.utils.GenericVersion
import no.uit.sfb.scalautils.common.FileUtils

import scala.concurrent.ExecutionContext
import scala.sys.process._
import scala.util.{Failure, Success, Try}

case class Artifact(packageName: String, version: String) extends LazyLogging {
  implicit val ec = ExecutionContext.global
  val localPath = Paths.get(packageName).resolve(version)
  val artifactName = s"${packageName}_$version.tgz"
  def url(artifactsUrl: URL): URL =
    new URL(s"$artifactsUrl/$packageName/$artifactName")

  def toPackage = Package(packageName, Map(version -> this))

  /**
    * Download the artifact and extracts it.
    * When the function is entered, a lock is materialized as a file created atomically. When the function exits, the file is deleted (not atomically but it does not matter at that point).
    * In case two jvm instances try to download at the same time, only one will effectively download the artifact, while the second one will only wait for the lock file to disappear.
    * Note: This is just an attempt make the download function process-safe but there is really no guaranty that this implementation is really safe.
    * If overwrite is set to false, the downloading is skipped if the package is found.
    * If force is set to true and the artifact is locked, remove the lock and delete the matching directory (as it is assumed only partially downloaded)
    */
  def download(dir: Path,
               artifactsUrl: URL,
               overwrite: Boolean = false,
               force: Boolean): Unit = {
    val packageDir = dir.resolve(packageName.toString)

    Try {
      if (!FileUtils.exists(packageDir.resolve(s"$version")) || overwrite) {
        println(s"Downloading $this (in $dir)... (this may take a while)")

        val target =
          packageDir.resolve(s"${packageDir.getFileName}/$version")
        FileUtils.deleteDirIfExists(target)
        FileUtils.createDirs(packageDir)

        val ret =
          Process(
            s"""curl --write-out "%{http_code}" -sO ${url(artifactsUrl)}""",
            dir.toFile).!!
        if (ret.replace("\"", "").replace("\n", "").toInt >= 400)
          throw new Exception(
            s"Dependency (${url(artifactsUrl)}) download failed with code: '$ret'")
        println(
          s"Extracting archive $artifactName (to $packageDir)... (this may take a while)")
        s"tar -xvzf $dir/$artifactName -C $packageDir --strip-components=1".!!
        s"rm $dir/$artifactName".!!
        s"chmod -R 777 $packageDir".!!
      } else
        println(s"$this already installed")
    } match {
      case Success(_) =>
        println(s"$artifactName is downloaded and unpacked")
      case Failure(ex) => throw ex
    }
  }

  def removeOlderVersions(dir: Path): Unit = {

    try {
      val toRemove = FileUtils.ls(dir.resolve(packageName))._1 flatMap { p =>
        Artifact.parse(s"${packageName}_${p.getFileName}.tgz")
      } filter { _ < this }
      toRemove foreach { a =>
        println(s"Removing older $a")
        FileUtils.deleteDirIfExists(dir.resolve(a.localPath))
      }
    } catch {
      case e: NoSuchFileException =>
        FileUtils.createDirs(dir.resolve(packageName))
    }
  }
}

object Artifact extends Ordering[Artifact] {
  def parse(artifactName: String): Option[Artifact] = {
    artifactName.split("\\.tgz").headOption flatMap { fullName =>
      fullName.split('_').toList match {
        case p :: pVersion :: Nil =>
          Some(Artifact(p, pVersion)) //We ignore the aVersion
        case p :: pVersion :: _ :: Nil =>
          Some(Artifact(p, pVersion)) //We ignore the aVersion
        case _ => None
      }
    }
  }

  def compare(x: Artifact, y: Artifact): Int = {
    if (x.packageName != y.packageName)
      throw new Exception(
        s"Cannot compare artifacts with different package names (${x.packageName} vs ${y.packageName})")
    GenericVersion.compare(x.version, y.version)
  }
}
