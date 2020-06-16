include {PreProcessContigs} from './process/preProcessContigs.nf'

workflow FA {
  take:
    contigs

  main:
    PreProcessContigs(contigs)


  //emit:
  //  trimmedMerged = TrimmomaticSE.out.merged
}