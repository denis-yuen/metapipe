params.refdb = 'kaiju-mardb:1.7.2'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {KaijuProc} from './process/kaiju-proc.nf'

workflow Kaiju {
  take:
    input

  main:
    refdb = DownloadRefDb(params.refdb)
    KaijuProc(refdb, input)

  emit:
    kaiju = KaijuProc.out
}
