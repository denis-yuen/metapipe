#!/usr/bin/env nextflow

// import modules
include {PreProcessReads} from './modules/PreProcessReads.nf'
include {Seqprep} from './modules/Seqprep.nf'
include {TrimmomaticSE; TrimmomaticPE} from './modules/Trimmomatic.nf'
include {Rrnapred} from './modules/Rrnapred.nf'
include {PairReads} from './modules/PairReads.nf'
include {Megahit} from './modules/Megahit.nf'

workflow Assembly {
  take:
    read_pairs_ch
  main:
    PreProcessReads(read_pairs_ch) | flatten | map { path -> tuple(path.baseName, path) } | Seqprep
    merged_ch = Seqprep.out.merged.collectFile(name: 'merged.fastq.gz', sort: {it.parent.baseName})
    unmergedR1_ch = Seqprep.out.unmergedR1.collectFile(name: 'unmergedR1.fastq.gz', sort: {it.parent.baseName})
    unmergedR2_ch = Seqprep.out.unmergedR2.collectFile(name: 'unmergedR2.fastq.gz', sort: {it.parent.baseName})
    TrimmomaticSE(merged_ch)
    TrimmomaticPE(unmergedR1_ch, unmergedR2_ch)
    TrimmomaticSE.out.merged.mix(TrimmomaticPE.out.unmergedR1,TrimmomaticPE.out.unmergedR2).map{ path -> tuple(path.simpleName, path) } | Rrnapred
    PairReads(Rrnapred.out.unmergedR1_filtered, Rrnapred.out.unmergedR2_filtered)
    Megahit(PairReads.out.r1, PairReads.out.r2, Rrnapred.out.merged_filtered)
  emit:
    contigs = Megahit.out.contigs
}
