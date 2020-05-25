package no.uit.sfb.stages.postprocessingmga

import java.nio.file.Path

case class Config(
    contigsPath: Path = null,
    mgaOutputPath: Path = null,
    outPath: Path = null,
    removeNonCompleteGenes: Boolean = false
)
