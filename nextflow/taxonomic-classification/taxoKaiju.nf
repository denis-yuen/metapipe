params.Kaiju_refdb = 'kaiju-mardb:1.7.2'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {Kaiju} from './process/kaiju.nf'

workflow TaxoKaiju {
  take:
    merged
    r1
    r2

  main:
    refdb = DownloadRefDb(params.Kaiju_refdb)
    Kaiju(refdb, merged, r1, r2)

  emit:
    kaiju = Kaiju.out.taxo
}
