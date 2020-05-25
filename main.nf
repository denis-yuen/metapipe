#!/usr/bin/env nextflow

nextflow.preview.dsl = 2

/*
 * Default pipeline parameters. They can be overriden on the command line eg.
 * given `params.foo` specify on the run command line `--foo some_value`.
 */
params.PreProcessReads_slices = 4

log.info """\
 M E T A P I P E
 ===================================
 slices: ${params.PreProcessReads_slices}
 """

// import modules
include {PreProcessReads} from './nextflow/Assembly/modules/PreProcessReads.nf'
include {Seqprep} from './nextflow/Assembly/modules/Seqprep.nf'

 workflow {
   reads = '../test/default-it/src/test/resources/datasets/default_reads_fastq'
   read_pairs_ch = Channel.fromPath( reads + '/*.fastq*', checkIfExists: true ) | collect | view
   PreProcessReads(read_pairs_ch) | flatMap | Seqprep
 }

 /*
  * completion handler
  */
 workflow.onComplete {
 	log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
 }