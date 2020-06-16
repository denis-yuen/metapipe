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
include {TaxonomicClassification} from './nextflow/taxonomic-classification/taxonomicClassification.nf'
include {FunctionalAssignment} from './nextflow/functional-assignment/functionalAssignment.nf'

workflow {
  read_pairs_ch = Channel.fromPath( params.reads + '/*.fastq*', checkIfExists: true ) | collect
  Assembly(read_pairs_ch)
  Binning(Assembly.out.contigs, Assembly.out.trimmedMerged, Assembly.out.trimmedR1, Assembly.out.trimmedR2)
  filtered = Assembly.out.filteredMerged.concat(Assembly.out.filteredR1, Assembly.out.filteredR2).collectFile(name: 'filtered.fastq.gz', newLine: false)
  pred16s = Assembly.out.pred16sMerged.concat(Assembly.out.pred16sR1, Assembly.out.pred16sR2).collectFile(name: 'pred16s.fasta', newLine: false)
  TaxonomicClassification(filtered, pred16s)
  FunctionalAssignment(Assembly.out.contigs)
}

 /*
  * completion handler
  */
/*workflow.onComplete {
  log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
}*/
