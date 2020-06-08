#!/usr/bin/env nextflow

// import modules
include {BbWrap} from './modules/bbwrap.nf'
include {BbPileup} from './modules/bbpileup.nf'

workflow Binning {
  take:
    contigs
    trimmedMerged
    trimmedR1
    trimmedR2
  main:
    BbWrap(contigs, trimmedMerged, trimmedR1, trimmedR2)
    BbPileup(BbWrap.out.alignment)
  //emit:
  //  xx = yyy
}
