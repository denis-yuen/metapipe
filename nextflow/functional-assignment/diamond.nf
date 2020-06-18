params.refdb = 'diamond-marref-proteins:4'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {DiamondProc} from './process/diamond-proc.nf'

workflow Diamond {
  take:
    input

  main:
    refdb = DownloadRefDb(params.refdb)
    diamond_ch = DiamondProc(refdb, input) | collectFile()

  emit:
    diamond = diamond_ch
}