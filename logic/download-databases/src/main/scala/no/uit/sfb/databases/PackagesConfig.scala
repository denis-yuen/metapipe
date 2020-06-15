package no.uit.sfb.metapipe

import java.net.URL
import java.nio.file.{Path, Paths}

import no.uit.sfb.metapipe.utils.ArtifactCreds

case class PackagesConfig(
    cmd: String = "",
    dir: Path = Paths.get(sys.env("HOME")).resolve("packages"),
    packages: Set[String] = Set(),
    packageName: String = "",
    overwrite: Boolean = false,
    force: Boolean = false,
    cleanup: Boolean = false,
    artifactsUrl: URL = new URL(
      "https://artifactory.metapipe.uit.no/artifactory/generic-local/no.uit.sfb/metapipe_dependencies"),
    imageName: String = "",
    artifactoryUser: Option[String] = ArtifactCreds.user,
    artifactoryPassword: Option[String] = ArtifactCreds.password
)
