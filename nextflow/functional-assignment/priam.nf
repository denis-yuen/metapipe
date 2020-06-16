params.Priam_refdb = 'priam:JAN18'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {PriamSearchProc} from './process/priamSearch-proc.nf'

workflow Priam {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Priam_refdb)
    PriamSearchProc(refdb, input)

  emit:
    priam = PriamSearchProc.out.priam
}
