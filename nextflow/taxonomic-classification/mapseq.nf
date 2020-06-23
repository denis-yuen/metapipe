params.refdbDir = "${baseDir}/refdb"
params.refdb = 'silvamar:4'

include {DownloadRefDb} from '../helper/downloadRefDb.nf' params(refdbDir: params.refdbDir)
include {MapseqProc} from './process/mapseq-proc.nf'

workflow Mapseq {
  take:
    input

  main:
    DownloadRefDb(params.refdb)
    refdb = DownloadRefDb.out.dbPath
    MapseqProc(refdb, input)

  emit:
    mapseq = MapseqProc.out
}
