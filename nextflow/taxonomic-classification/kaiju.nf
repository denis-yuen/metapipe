params.refdbDir = '${baseDir}/refdb'
params.refdb = 'kaiju-mardb:1.7.2'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {KaijuProc} from './process/kaiju-proc.nf'

def mem(refdb) {
  file("${refdb}/db/kaiju/**/*.fmi")[0].size()
}

workflow Kaiju {
  take:
    input

  main:
    dbsize = DownloadRefDb(params.refdb).out.extDbPath.map{path -> mem(path)}
    KaijuProc(DownloadRefDb.out.dbPath, input, dbsize)

  emit:
    kaiju = KaijuProc.out
}
