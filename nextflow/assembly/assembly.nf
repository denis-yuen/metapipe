include {PreProcessReads} from './process/preProcessReads.nf' params()
include {Seqprep} from './process/seqprep.nf'
include {TrimmomaticSE; TrimmomaticPE} from './process/trimmomatic.nf' params(readsCutoff: params.readsCutoff)
include {Rrnapred} from './process/rrnapred.nf'
include {PairReads} from './process/pairReads.nf'
include {Megahit} from './process/megahit.nf' params(contigsCutoff: params.contigsCutoff)

workflow Assembly {
  take:
    read_pairs_ch

  main:
    PreProcessReads(read_pairs_ch) | flatten | map { path -> tuple(path.baseName, path) } | Seqprep
    merged = Seqprep.out.merged.collectFile(sort: {it.parent.baseName})
    unmergedR1 = Seqprep.out.unmergedR1.collectFile(sort: {it.parent.baseName})
    unmergedR2 = Seqprep.out.unmergedR2.collectFile(sort: {it.parent.baseName})
    TrimmomaticSE(merged)
    TrimmomaticPE(unmergedR1, unmergedR2)
    TrimmomaticSE.out.merged.mix(TrimmomaticPE.out.unmergedR1,TrimmomaticPE.out.unmergedR2).map{ path -> tuple(path.simpleName, path) } | Rrnapred
    PairReads(Rrnapred.out.unmergedR1_filtered, Rrnapred.out.unmergedR2_filtered)
    filtered = Rrnapred.out.merged_filtered.concat(Rrnapred.out.unmergedR1_filtered, Rrnapred.out.unmergedR2_filtered).collectFile(name: 'filtered.fastq.gz', newLine: false)
    pred16s = Rrnapred.out.merged_pred16s.concat(Rrnapred.out.unmergedR1_pred16s, Rrnapred.out.unmergedR2_pred16s).collectFile(name: 'pred16s.fasta', newLine: false)
    Megahit(PairReads.out.r1, PairReads.out.r2, Rrnapred.out.merged_filtered)
    export_ch = filtered.mix(pred16s, Megahit.out.contigs)

  emit:
    trimmedMerged = TrimmomaticSE.out.merged
    trimmedR1 = TrimmomaticPE.out.unmergedR1
    trimmedR2 = TrimmomaticPE.out.unmergedR2
    filtered = filtered
    pred16s = pred16s
    contigs = Megahit.out.contigs
    export = export_ch
}
