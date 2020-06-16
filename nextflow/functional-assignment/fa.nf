include {PreProcessContigs} from './process/preProcessContigs.nf'
include {Mga} from './process/mga.nf'
include {GeneExtractor} from './process/geneExtractor.nf'
include {FaPriam} from './faPriam.nf'
include {FaDiamond} from './faDiamond.nf'

workflow FA {
  take:
    contigs

  main:
    contigs_ch = PreProcessContigs(contigs) | flatten | map { path -> tuple(path.baseName, path) }
    mga_ch = Mga(contigs_ch) | flatten | map { path -> tuple(path.baseName, path) }
    cds_ch = contigs_ch.join(mga_ch) | GeneExtractor | flatten | map { path -> tuple(path.baseName, path) }
    FaPriam(cds_ch)
    FaDiamond(cds_ch)

  //emit:
  //  trimmedMerged = TrimmomaticSE.out.merged
}