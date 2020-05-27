package no.uit.sfb.metapipe.rrnapred

import java.nio.file.{Path, Paths}

case class Config(
    hmmDir: Path = Paths.get("/data"),
    hmmerPath: Path = Paths.get("/app/hmmsearch"),
    fastqPath: Path = null, //input
    out: Path = null, //output
    eValue: Double = 10e-5,
    cpu: Int = 1
)
