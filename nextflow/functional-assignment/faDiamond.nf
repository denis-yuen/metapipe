params.Diamond_refdb = 'diamond-marref-proteins:4'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {Diamond} from './process/diamond.nf'

workflow FaDiamond {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Diamond_refdb)
    Diamond(refdb, input)

  emit:
    priam = Diamond.out.diamond
}