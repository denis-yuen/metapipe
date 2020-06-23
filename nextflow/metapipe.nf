/*
 * Default pipeline parameters. They can be overridden on the command line eg.
 * given `params.foo` specify on the run command line `--foo some_value`.
 */
params.refdbDir = "${baseDir}/refdb"
params.exportDir = "."
params.reads = "${baseDir}/test/resources/datasets/default_reads_fastq/{forward,reverse}.fastq*"
params.readsCutoff = 75
params.contigsCutoff = 1000
params.kaiju_refdb = 'kaiju-mardb:1.7.2'                 //'kaiju-refseq:1.7.2'
params.mapseq_refdb = 'silvamar:4'                       //':'
params.functionalAnnotation_removeIncompleteGenes = false
params.diamond_refdb = 'diamond-marref-proteins:4'       //'diamond-uniref50:2019-06'
params.diamond_sensitivity = 'sensitive'                 //''|'more-sensitive'
params.interpro_refdb = 'interpro:5.42-78.0'
params.priam_refdb = 'priam:JAN18'

log.info """
 M E T A P I P E
 ===================================
 refdbDir: ${params.refdbDir}
 exportDir: ${params.exportDir}
 reads: ${params.reads}
 readsCutoff: ${params.readsCutoff}
 contigsCutoff: ${params.contigsCutoff}
 kaiju_refdb: ${params.kaiju_refdb}
 mapseq_refdb: ${params.mapseq_refdb}
 functionalAnnotation_removeIncompleteGenes: ${params.functionalAnnotation_removeIncompleteGenes}
 diamond_refdb: ${params.diamond_refdb}
 diamond_sensitivity: ${params.diamond_sensitivity}
 interpro_refdb: ${params.interpro_refdb}
 priam_refdb: ${params.priam_refdb}
 """

// import modules
include {Assembly} from './assembly/assembly.nf'
include {Binning} from './binning/binning.nf'
include {TaxonomicClassification} from './taxonomic-classification/taxonomicClassification.nf'
include {FunctionalAssignment} from './functional-assignment/functionalAssignment.nf'
include {Export} from './helper/export.nf'

workflow Metapipe {
  read_pairs_ch = Channel.fromPath(params.reads, checkIfExists: true).take(2).toSortedList() | view
  Assembly(read_pairs_ch)
  Binning(Assembly.out.contigs, Assembly.out.trimmedMerged, Assembly.out.trimmedR1, Assembly.out.trimmedR2)
  TaxonomicClassification(Assembly.out.filtered, Assembly.out.pred16s)
  FunctionalAssignment(Assembly.out.contigs)
  Export(Assembly.out.export, Binning.out.export, TaxonomicClassification.out.export, FunctionalAssignment.out.export)
}

