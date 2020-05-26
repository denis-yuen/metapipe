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
include {PreProcessReads} from './nextflow/Assembly/modules/PreProcessReads.nf'
include {Seqprep} from './nextflow/Assembly/modules/Seqprep.nf'
include {TrimmomaticSE; TrimmomaticPE} from './nextflow/Assembly/modules/Trimmomatic.nf'
include {Rrnapred} from './nextflow/Assembly/modules/Rrnapred.nf'
include {PairReads} from './nextflow/Assembly/modules/PairReads.nf'
include {Megahit} from './nextflow/Assembly/modules/Megahit.nf'

 workflow {
   read_pairs_ch = Channel.fromPath( params.reads + '/*.fastq*', checkIfExists: true ) | collect
   PreProcessReads(read_pairs_ch) | flatten | map { path -> tuple(path.baseName, path) } | Seqprep
   merged_ch = Seqprep.out.merged.collectFile(name: 'merged.fastq.gz', sort: {it.parent.baseName})
   unmergedR1_ch = Seqprep.out.unmergedR1.collectFile(name: 'unmergedR1.fastq.gz', sort: {it.parent.baseName})
   unmergedR2_ch = Seqprep.out.unmergedR2.collectFile(name: 'unmergedR2.fastq.gz', sort: {it.parent.baseName})
   TrimmomaticSE(merged_ch)
   TrimmomaticPE(unmergedR1_ch, unmergedR2_ch)
   TrimmomaticSE.out.merged.mix(TrimmomaticPE.out.unmergedR1,TrimmomaticPE.out.unmergedR2).map{ path -> tuple(path.simpleName, path) } | Rrnapred
   PairReads(Rrnapred.out.unmergedR1_filtered, Rrnapred.out.unmergedR2_filtered)
   Megahit(PairReads.out.r1, PairReads.out.r2, Rrnapred.out.merged_filtered)
 }

 /*
  * completion handler
  */
 workflow.onComplete {
 	log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
 }