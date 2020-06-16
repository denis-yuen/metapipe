params.Mapseq_refdb = 'silvamar:4'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {MapseqProc} from './process/mapseq-proc.nf'

workflow Mapseq {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Mapseq_refdb)
    MapseqProc(refdb, input)

  emit:
    mapseq = MapseqProc.out.taxo
}
