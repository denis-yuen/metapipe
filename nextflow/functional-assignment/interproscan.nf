params.Interpro_refdb = 'interpro:5.42-78.0'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {InterproscanProc} from './process/interproscan-proc.nf'

workflow Interproscan {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Interpro_refdb)
    interpro_ch = InterproscanProc(refdb, input) | collectFile()

  emit:
    interpro = interpro_ch
}