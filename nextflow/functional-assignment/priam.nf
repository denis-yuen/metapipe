params.refdb = 'priam:JAN18'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {PriamSearchProc} from './process/priamSearch-proc.nf'

workflow Priam {
  take:
    input

  main:
    refdb = DownloadRefDb(params.refdb)
    PriamSearchProc(refdb, input)
    genomeECs = PriamSearchProc.out.genomeECs | collectFile()
    genomeEnzymes = PriamSearchProc.out.genomeEnzymes | collectFile()
    predictableECs = PriamSearchProc.out.predictableECs | collectFile()
    sequenceECs = PriamSearchProc.out.sequenceECs | collectFile()
    priam = genomeECs.mix(genomeEnzymes, predictableECs, sequenceECs)

  emit:
    priam = priam
}
