include {PreProcessContigs} from './process/preProcessContigs.nf' params(contigsCutoff: params.contigsCutoff)
include {Mga} from './process/mga.nf'
include {GeneExtractor} from './process/geneExtractor.nf' params(removeIncompleteGenes: params.functionalAnnotation_removeIncompleteGenes)
include {Priam} from './priam.nf' params(refdb: params.priam_refdb, refdbDir: params.refdbDir)
include {Diamond} from './diamond.nf' params(refdb: params.diamond_refdb, sensitivity: params.diamond_sensitivity, refdbDir: params.refdbDir)
include {Interproscan} from './interproscan.nf' params(refdb: params.interpro_refdb, refdbDir: params.refdbDir)

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
    export_ch = Diamond.out.mix(Priam.out, Interproscan.out) | collect

  emit:
    export = export_ch
}