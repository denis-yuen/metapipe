package no.uit.sfb.databases

import java.net.URL

import scala.sys.process._

object PackageLister {
  def listAll(artifactsUrl: URL): Map[String, Package] = {
    val rep = s"curl -sL $artifactsUrl".!!
    val artifactList = (for {
      line <- rep.split("\n")
      packageName <- parseLine(line) if !packageName.contains(".tgz")
    } yield {
      val rep = s"curl -sL $artifactsUrl/$packageName".!!
      for {
        line <- rep.split("\n")
        artifactName <- parseLine(line)
        artifact <- Artifact.parse(artifactName)
      } yield artifact
    }).flatten
    artifactList.foldLeft(Map[String, Package]())((acc, artifact) => {
      val updatedPackage = acc.get(artifact.packageName) match {
        case Some(p) =>
          p.artifacts.get(artifact.version) match {
            case Some(a) =>
              p
            case None =>
              p ++ artifact.toPackage
          }
        case None =>
          artifact.toPackage
      }
      acc + (updatedPackage.packageName -> updatedPackage)
    })
  }

  def listPackage(packageName: String, artifactsUrl: URL): Package = {
    listAll(artifactsUrl)
      .getOrElse(packageName, Package(packageName, Map()))
  }

  def parseLine(str: String): Option[String] = {
    str.split("<a href=\"").toList match {
      case "" :: a :: Nil =>
        a.split("\">").headOption
      case _ =>
        None
    }
  }
}
