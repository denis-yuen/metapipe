#!/usr/bin/env nextflow

nextflow.preview.dsl = 2

/*
 * Default pipeline parameters. They can be overridden on the command line eg.
 * given `params.foo` specify on the run command line `--foo some_value`.
 */
params.reads = "$baseDir/test/resources/datasets/default_reads_fastq"

log.info """
 M E T A P I P E
 ===================================
 reads: ${params.reads}
 """

// import modules
include {Assembly} from './nextflow/assembly/assembly.nf'
include {Binning} from './nextflow/binning/binning.nf'
include {TaxoKaiju} from './nextflow/taxonomic-classification/taxoKaiju.nf'

workflow {
  read_pairs_ch = Channel.fromPath( params.reads + '/*.fastq*', checkIfExists: true ) | collect
  Assembly(read_pairs_ch)
  //Binning(Assembly.out.contigs, Assembly.out.trimmedMerged, Assembly.out.trimmedR1, Assembly.out.trimmedR2)
  TaxoKaiju(Assembly.out.filteredMerged, Assembly.out.filteredR1, Assembly.out.filteredR2)
}

 /*
  * completion handler
  */
/*workflow.onComplete {
  log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
}*/