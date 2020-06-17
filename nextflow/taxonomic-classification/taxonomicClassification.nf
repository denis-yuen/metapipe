include {Kaiju} from './kaiju.nf' params(refdb: params.kaiju_refdb)
include {Mapseq} from './mapseq.nf' params(refdb: params.mapseq_refdb)

workflow TaxonomicClassification {
  take:
    filtered
    pred16s

  main:
    Kaiju(filtered)
    Mapseq(pred16s)

  emit:
    kaiju = Kaiju.out
    mapseq = Mapseq.out
}