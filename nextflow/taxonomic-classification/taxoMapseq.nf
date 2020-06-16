params.Mapseq_refdb = 'silvamar:4'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {Mapseq} from './process/mapseq.nf'

workflow TaxoMapseq {
  take:
    merged
    r1
    r2

  main:
    refdb = DownloadRefDb(params.Mapseq_refdb)
    Mapseq(refdb, merged, r1, r2)

  emit:
    mapseq = Mapseq.out.taxo
}
