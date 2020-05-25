package no.uit.sfb.stages.egress

import java.net.URL
import java.nio.file.Path

import no.uit.sfb.apis.storage.ObjectId

case class Config(
    url: URL = new URL("http://localhost"),
    access: String = "admin",
    secret: String = "",
    bucketName: String = "",
    location: ObjectId = ObjectId.fromString(""),
    cpu: Int = 1,
    outDir: Path = null,
    paths: Map[Path, ObjectId] = Map()
)
