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
    contigs = PreProcessContigs(contigs) | flatten | map { path -> tuple(path.baseName, path) }
    mga = Mga(contigs) | flatten | map { path -> tuple(path.baseName, path) }
    cds = contigs.join(mga) | GeneExtractor | flatten | map { path -> tuple(path.baseName, path) }
    Priam(cds)
    Diamond(cds)
    Interproscan(cds)

  emit:
    interpro = Interproscan.out
    diamond = Diamond.out
    priam_genomeECs = Priam.out.genomeECs
    priam_genomeEnzymes = Priam.out.genomeEnzymes
    priam_predictableECs = Priam.out.predictableECs
    priam_sequenceECs = Priam.out.sequenceECs
}