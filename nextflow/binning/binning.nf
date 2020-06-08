#!/usr/bin/env nextflow

// import modules
include {BbWrap} from './modules/bbwrap.nf'
include {BbPileup} from './modules/bbpileup.nf'
include {Maxbin} from './modules/maxbin.nf'
include {BbSketch} from './modules/bbsketch.nf'

workflow Binning {
  take:
    contigs
    trimmedMerged
    trimmedR1
    trimmedR2
  main:
    BbWrap(contigs, trimmedMerged, trimmedR1, trimmedR2)
    BbPileup(BbWrap.out.alignment)
    Maxbin(contigs, BbPileup.out.coverage) | BbSketch
  //emit:
  //  xx = yyy
}
