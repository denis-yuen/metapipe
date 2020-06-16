params.Interpro_refdb = 'interpro:5.42-78.0'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {Interproscan} from './process/interproscan.nf'

workflow FaInterproscan {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Interpro_refdb)
    Interproscan(refdb, input)

  emit:
    priam = Interproscan.out.interpro
}