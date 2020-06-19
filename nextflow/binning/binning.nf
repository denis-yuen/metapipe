include {BbWrap} from './process/bbwrap.nf'
include {BbPileup} from './process/bbpileup.nf'
include {Maxbin} from './process/maxbin.nf'
include {BbSketch} from './process/bbsketch.nf'

workflow Binning {
  take:
    contigs
    trimmedMerged
    trimmedR1
    trimmedR2

  main:
    BbWrap(contigs, trimmedMerged, trimmedR1, trimmedR2)
    BbPileup(BbWrap.out.alignment)
    Maxbin(contigs, BbPileup.out.coverage) | flatten | BbSketch
    export_ch = BbSketch.out.bin | collect

  emit:
    bins = BbSketch.out.bin
    export = export_ch
}
