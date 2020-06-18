params.refdb = 'kaiju-mardb:1.7.2'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {KaijuProc} from './process/kaiju-proc.nf'

def mem(refdb) {
  file("${params.metapipeDir}${refdb}/db/kaiju/**/*.fmi")[0].size()
}

workflow Kaiju {
  take:
    input

  main:
    refdb = DownloadRefDb(params.refdb)
    dbsize = refdb.map{path -> mem(path)}
    KaijuProc(refdb, input, dbsize)

  emit:
    kaiju = KaijuProc.out
}
