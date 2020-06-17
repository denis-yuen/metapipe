include {PreProcessContigs} from './process/preProcessContigs.nf' params(slices: params.functionalAnnotation_slices, contigsCutoff: params.contigsCutoff)
include {Mga} from './process/mga.nf'
include {GeneExtractor} from './process/geneExtractor.nf' params(removeIncompleteGenes: params.functionalAnnotation_removeIncompleteGenes)
include {Priam} from './priam.nf' params(refdb: params.priam_refdb)
include {Diamond} from './diamond.nf' params(refdb: params.diamond_refdb, sensitivity: params.diamond_sensitivity)
include {Interproscan} from './interproscan.nf' params(refdb: params.interpro_refdb, toolsCpu: params.interpro_toolsCpu, maxWorkers: params.interpro_maxWorkers, precalcService: params.interpro_precalcService)

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