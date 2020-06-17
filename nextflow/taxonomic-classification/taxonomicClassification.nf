include {Kaiju} from './kaiju.nf'
include {Mapseq} from './mapseq.nf'

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