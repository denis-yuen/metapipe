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
include {TrimmomaticSE; TrimmomaticPE} from './nextflow/Assembly/modules/Trimmomatic.nf'
include {Rrnapred} from './nextflow/Assembly/modules/Rrnapred.nf'

 workflow {
   reads = '../test/default-it/src/test/resources/datasets/default_reads_fastq'
   read_pairs_ch = Channel.fromPath( reads + '/*.fastq*', checkIfExists: true ) | collect
   PreProcessReads(read_pairs_ch) | flatMap | Seqprep
   merged_ch = Seqprep.out.merged.collectFile(name: 'merged.fastq.gz')
   unmergedR1_ch = Seqprep.out.slicesR1.collectFile(name: 'unmergedR1.fastq.gz')
   unmergedR2_ch = Seqprep.out.slicesR2.collectFile(name: 'unmergedR2.fastq.gz')
   TrimmomaticSE(merged_ch)
   TrimmomaticPE(unmergedR1_ch, unmergedR2_ch)
   TrimmomaticSE.out.merged.mix(TrimmomaticPE.out.unmergedR1,TrimmomaticPE.out.unmergedR2) | view
 }

 /*
  * completion handler
  */
 workflow.onComplete {
 	log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
 }