include {PreProcessContigs} from './process/preProcessContigs.nf'
include {Mga} from './process/mga.nf'
include {GeneExtractor} from './process/geneExtractor.nf'

workflow FA {
  take:
    contigs

  main:
    contigs_ch = PreProcessContigs(contigs) | flatten | map { path -> tuple(path.baseName, path) }
    mga_ch = Mga(contigs_ch) | flatten | map { path -> tuple(path.baseName, path) }
    contigs_ch.join(mga_ch) | GeneExtractor


  //emit:
  //  trimmedMerged = TrimmomaticSE.out.merged
}