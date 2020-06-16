package no.uit.sfb.metapipe

import no.uit.sfb.metapipe.utils.GenericVersion

case class Package(packageName: String, artifacts: Map[String, Artifact]) {
  def ++(other: Package): Package = {
    if (packageName != other.packageName)
      throw new Exception(
        s"Cannot compare not related dependencies (${other.packageName} != $packageName)")
    else
      this.copy(artifacts = artifacts ++ other.artifacts)
  }

  lazy val latest: Artifact = {
    if (artifacts.nonEmpty) {
      artifacts.values.maxBy(_.version)(GenericVersion)
    } else
      throw new Exception(
        s"Could not find any version for package '$packageName'")
  }

  def get(version: Option[String]): Artifact = {
    version match {
      case Some(odv) =>
        artifacts.getOrElse(
          odv,
          throw new Exception(s"Version $odv not found for $packageName"))
      case None => latest
    }
  }
}
