params.Interpro_refdb = 'interpro:5.42-78.0'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {InterproscanProc} from './process/interproscan-proc.nf'

workflow Interproscan {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Interpro_refdb)
    InterproscanProc(refdb, input)

  emit:
    priam = InterproscanProc.out.interpro
}