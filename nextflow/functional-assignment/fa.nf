include {PreProcessContigs} from './process/preProcessContigs.nf'
include {Mga} from './process/mga.nf'

workflow FA {
  take:
    contigs

  main:
    PreProcessContigs(contigs) | flatten | map { path -> tuple(path.baseName, path) } | Mga


  //emit:
  //  trimmedMerged = TrimmomaticSE.out.merged
}