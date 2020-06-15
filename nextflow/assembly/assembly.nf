// import modules
include {PreProcessReads} from './modules/preProcessReads.nf'
include {Seqprep} from './modules/seqprep.nf'
include {TrimmomaticSE; TrimmomaticPE} from './modules/trimmomatic.nf'
include {Rrnapred} from './modules/rrnapred.nf'
include {PairReads} from './modules/pairReads.nf'
include {Megahit} from './modules/megahit.nf'

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
    trimmedMerged = TrimmomaticSE.out.merged
    trimmedR1 = TrimmomaticPE.out.unmergedR1
    trimmedR2 = TrimmomaticPE.out.unmergedR2
    filteredMerged = Rrnapred.out.merged_filtered
    filteredR1 = Rrnapred.out.unmergedR1_filtered
    filteredR2 = Rrnapred.out.unmergedR2_filtered
    contigs = Megahit.out.contigs
}
