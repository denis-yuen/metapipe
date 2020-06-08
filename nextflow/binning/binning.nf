#!/usr/bin/env nextflow

// import modules
include {Bbwrap} from './modules/bbwrap.nf'

workflow Binning {
  take:
    contigs
    trimmedMerged
    trimmedR1
    trimmedR2
  main:
    Bbwrap(contigs, trimmedMerged, trimmedR1, trimmedR2)
  //emit:
  //  xx = yyy
}
