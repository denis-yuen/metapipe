params.Priam_refdb = 'priam:JAN18'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {PriamSearch} from './process/priamSearch.nf'

workflow FaPriam {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Priam_refdb)
    PriamSearch(refdb, input)

  emit:
    priam = PriamSearch.out.priam
}
