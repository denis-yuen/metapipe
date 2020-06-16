package no.uit.sfb.metapipe

import java.nio.file.Path

case class Config(
    inputPath: Path = null,
    outPath: Path = null,
    contigsCutoff: Int = 200,
    slices: Int = 1
)
