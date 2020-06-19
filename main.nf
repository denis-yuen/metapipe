#!/usr/bin/env nextflow

nextflow.preview.dsl = 2


include {Metapipe} from './nextflow/metapipe.nf'


workflow {
  Metapipe()
}

 /*
  * completion handler
  */
/*workflow.onComplete {
  log.info ( workflow.success ? "\nDone!" : "Oops .. something went wrong" )
}*/
