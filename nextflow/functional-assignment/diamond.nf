params.refdbDir = "${baseDir}/refdb"
params.refdb = 'diamond-marref-proteins:4'

include {DownloadRefDb} from '../helper/downloadRefDb.nf' params(refdbDir: params.refdbDir)
include {DiamondProc} from './process/diamond-proc.nf'

workflow Diamond {
  take:
    input

  main:
    DownloadRefDb(params.refdb)
    refdb = DownloadRefDb.out.dbPath
    diamond_ch = DiamondProc(refdb, input) | collectFile()

  emit:
    diamond = diamond_ch
}