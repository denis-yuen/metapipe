package no.uit.sfb.metapipe.preoprocessreads

import java.nio.file.Path

case class Config(
    r1OrInterleavedPath: Path = null, //input
    r2Path: Path = null, //input
    outputPath: Path = null, //output
    tmpPath: Path = null,
    slices: Int = 1,
    noSlicing: Boolean = false
)
