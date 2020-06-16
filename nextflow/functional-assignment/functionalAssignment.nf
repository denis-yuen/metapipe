include {PreProcessContigs} from './process/preProcessContigs.nf'
include {Mga} from './process/mga.nf'
include {GeneExtractor} from './process/geneExtractor.nf'
include {Priam} from './priam.nf'
include {Diamond} from './diamond.nf'
include {Interproscan} from './interproscan.nf'

workflow FunctionalAssignment {
  take:
    contigs

  main:
    contigs_ch = PreProcessContigs(contigs) | flatten | map { path -> tuple(path.baseName, path) }
    mga_ch = Mga(contigs_ch) | flatten | map { path -> tuple(path.baseName, path) }
    cds_ch = contigs_ch.join(mga_ch) | GeneExtractor | flatten | map { path -> tuple(path.baseName, path) }
    Priam(cds_ch)
    Diamond(cds_ch)
    Interproscan(cds_ch)

  //emit:
}