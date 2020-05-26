#!/usr/bin/env nextflow

nextflow.preview.dsl = 2

/*
 * Default pipeline parameters. They can be overriden on the command line eg.
 * given `params.foo` specify on the run command line `--foo some_value`.
 */
params.reads = '../test/default-it/src/test/resources/datasets/default_reads_fastq'

log.info """\
 M E T A P I P E
 ===================================
 reads: ${params.reads}
 """

// import modules
include {Assembly} from './nextflow/Assembly/Assembly.nf'

workflow {
  read_pairs_ch = Channel.fromPath( params.reads + '/*.fastq*', checkIfExists: true ) | collect
  Assembly(read_pairs_ch)
}

 /*
  * completion handler
  */
/*workflow.onComplete {
  log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
}*/