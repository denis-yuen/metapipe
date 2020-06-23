params.refdbDir = "${baseDir}/refdb"
params.refdb = 'interpro:5.42-78.0'

include {DownloadRefDb} from '../helper/downloadRefDb.nf' params(refdbDir: params.refdbDir)
include {InterproscanProc} from './process/interproscan-proc.nf'

workflow Interproscan {
  take:
    input

  main:
    DownloadRefDb(params.refdb)
    refdb = DownloadRefDb.out.dbPath
    interpro_ch = InterproscanProc(refdb, input) | collectFile()

  emit:
    interpro = interpro_ch
}