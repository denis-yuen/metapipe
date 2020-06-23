include {Kaiju} from './kaiju.nf' params(refdb: params.kaiju_refdb, refdbDir: params.refdbDir)
include {Mapseq} from './mapseq.nf' params(refdb: params.mapseq_refdb, refdbDir: params.refdbDir)

workflow TaxonomicClassification {
  take:
    filtered
    pred16s

  main:
    Kaiju(filtered)
    Mapseq(pred16s)
    export_ch = Kaiju.out.mix(Mapseq.out) | collect

  emit:
    kaiju = Kaiju.out
    mapseq = Mapseq.out
    export = export_ch
}