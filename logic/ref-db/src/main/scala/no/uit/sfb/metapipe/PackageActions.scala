package no.uit.sfb.metapipe

import java.net.URL
import java.nio.file.{Path, Paths}

import no.uit.sfb.scalautils.common.FileUtils
import no.uit.sfb.scalautils.json.Json

import scala.sys.process.Process
import scala.util.Try
import scala.sys.process._

object PackageActions {
  def apply(c: PackagesConfig): Unit = {
    lazy val depsTree: Map[String, Package] =
      PackageLister.listAll(c.artifactsUrl)

    c.cmd match {
      case "list" =>
        val artifacts = depsTree.values.toSeq
          .sortBy(_.packageName)
          .flatMap(
            _.artifacts.values.toSeq
              .sorted(Artifact)
              .map(_.artifactName))
        println(artifacts.mkString("\n"))
      case "latest" =>
        depsTree.get(c.packageName) match {
          case Some(up) =>
            val art = up.get(None)
            println(art.version)
          case None =>
            throw new Exception(s"Could not find package '${c.packageName}'")
        }
      case "download" =>
        val items: Map[Package, Option[String]] =
          (c.packages map { nameAndVersion =>
            val split = nameAndVersion.split('=')
            val packageName = split.head
            val oVersion = split.tail.headOption
            depsTree.get(packageName) match {
              case Some(up) =>
                up -> (oVersion map { ver =>
                  ver.split('_').toList match {
                    case a :: Nil => a
                    case _ =>
                      throw new Exception(
                        s"Wrong format for version '$ver'. Expected <depVersion>")
                  }
                })
              case None =>
                throw new IllegalArgumentException(
                  s"Package $packageName not defined.")
            }
          }).toMap
        download(items, c.dir, c.artifactsUrl, c.overwrite, c.force, c.cleanup)
      case "download-all" =>
        val items: Map[Package, Option[String]] =
          depsTree map {
            case (_, packager) =>
              packager -> None
          }
        download(items, c.dir, c.artifactsUrl, c.overwrite, c.force, c.cleanup)
      case "create" =>
        create(Paths.get("/tmp/metakube"),
               c.artifactsUrl,
               c.imageName,
               c.artifactoryUser,
               c.artifactoryPassword,
               depsTree,
               c.overwrite)
    }
  }

  private def create(artifactDir: Path,
                     artifactsUrl: URL,
                     imageName: String,
                     artifactoryUser: Option[String],
                     artifactoryPassword: Option[String],
                     depsTree: Map[String, Package],
                     overwrite: Boolean): Unit = {
    val md5Property = "md5Internal"
    case class ArtifactoryArtifactProperties(
        uri: String,
        properties: Map[String, Seq[String]])
    def getInternalMd5(artifact: Artifact): Option[String] = {
      val ret =
        s"""curl -s ${artifact.url(artifactsUrl)}?properties""".!!
      (Try(Json.parse[ArtifactoryArtifactProperties](ret)).toOption flatMap {
        _.properties.get(md5Property)
      }) flatMap { _.headOption }
    }

    println(s"Packaging $imageName...")
    val (_, toolName, tag) = {
      val (iName, iTag) = imageName.split(':').toList match {
        case n :: t :: Nil => n -> t
        case n :: Nil      => n -> "latest"
        case _             => "" -> ""
      }
      val split = iName.split('/')
      (split.init.mkString("'"), split.last, iTag)
    }
    val thisArtifact = {
      val splt = tag.split('_')
      Artifact(toolName, splt.headOption.getOrElse(""))
    }
    val oPrevious
      : Option[Artifact] = depsTree.get(thisArtifact.packageName) flatMap {
      up =>
        Try {
          up.get(Some(thisArtifact.version))
        }.toOption
    }
    val oPrevMd5 = oPrevious flatMap { prev =>
      println(s"Found artifact $prev")
      getInternalMd5(prev)
    }
    if (oPrevMd5.nonEmpty && !overwrite)
      println(
        s"Found artifact and md5 (${oPrevious.get}). Packaging cancelled.")
    else {
      val copyList: Seq[Path] = Seq(
        Paths.get("/app"),
        Paths.get("/db")
      )
      val cpToPath = artifactDir.resolve(toolName).resolve(tag)
      FileUtils.deleteDirIfExists(cpToPath)
      FileUtils.createDirs(cpToPath)
      val containerId = s"docker create $imageName none".!!.trim()
      copyList foreach { src =>
        s"docker cp $containerId:$src $cpToPath".! //may fail if src does not exist
      }
      s"docker rm $containerId".!!

      println("Computing checksum...")
      val md5Checksum = (
        Process(s"""find . -type f -print0""", cpToPath.toFile) #|
          "sort -z" #|
          Process(s"xargs -r0 md5sum", cpToPath.toFile) #|
          "md5sum"
      ).!!.split(' ').head
      println(s"Internal checksum: $md5Checksum")
      if (md5Checksum == oPrevMd5.getOrElse(""))
        println(
          s"Artifact ${oPrevious.get} has same internal checksum. Packaging cancelled.")
      else {
        println("Compressing...")
        val artifName = thisArtifact.artifactName
        val artifURL = thisArtifact.url(artifactsUrl)
        val artifactPath =
          artifactDir.resolve(artifName)
        FileUtils.deleteFileIfExists(artifactPath)
        Process(
          s"""tar -zcf $artifactPath ${artifactDir.relativize(cpToPath)}""",
          artifactDir.toFile).!!

        if (artifactoryUser.nonEmpty && artifactoryPassword.nonEmpty) {
          println("Uploading...")
          val ret =
            s"""curl -u ${artifactoryUser.get}:${artifactoryPassword.get} --output /dev/null --write-out "%{http_code}" -T $artifactPath $artifURL;$md5Property=$md5Checksum;)""".!!.replace(
              "\"",
              "").trim()
          FileUtils.deleteFile(artifactPath)
          if (ret.split('\n').last != "201") {
            println(s"Upload failed with code $ret")
            throw new Exception("Upload failed")
          }
        } else
          println(
            "Upload skipped since no Artifactory credentials provided (please use -u|--user and -p|--password options)")
      }
      FileUtils.deleteDirIfExists(cpToPath)
    }
  }

  private def download(items: Map[Package, Option[String]],
                       dir: Path,
                       artifactsUrl: URL,
                       overwrite: Boolean,
                       force: Boolean,
                       cleanup: Boolean): Unit = {
    if (items.isEmpty)
      println(s"Empty package list. Nothing to download.")
    items foreach {
      case (up, oDepVersion) =>
        val artifact = up.get(oDepVersion)
        if (cleanup) {
          artifact.removeOlderVersions(dir)
        }
        artifact.download(dir, artifactsUrl, overwrite, force)
    }
  }
}
