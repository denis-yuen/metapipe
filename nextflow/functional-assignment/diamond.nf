params.Diamond_refdb = 'diamond-marref-proteins:4'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {DiamondProc} from './process/diamond-proc.nf'

workflow Diamond {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Diamond_refdb)
    DiamondProc(refdb, input)

  emit:
    priam = DiamondProc.out.diamond
}