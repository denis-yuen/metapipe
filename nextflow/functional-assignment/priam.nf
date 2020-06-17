params.Priam_refdb = 'priam:JAN18'

include {DownloadRefDb} from '../helper/downloadRefDb.nf'
include {PriamSearchProc} from './process/priamSearch-proc.nf'

workflow Priam {
  take:
    input

  main:
    refdb = DownloadRefDb(params.Priam_refdb)
    PriamSearchProc(refdb, input)
    genomeECs = PriamSearchProc.out.genomeECs | collectFile()
    genomeEnzymes = PriamSearchProc.out.genomeEnzymes | collectFile()
    predictableECs = PriamSearchProc.out.predictableECs | collectFile()
    sequenceECs = PriamSearchProc.out.sequenceECs | collectFile()

  emit:
    genomeECs = genomeECs
    genomeEnzymes = genomeEnzymes
    predictableECs = predictableECs
    sequenceECs = sequenceECs
}
