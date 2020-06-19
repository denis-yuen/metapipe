params.exportDir = '.'

process Export {
  label 'helper'

  publishDir "${params.exportDir}"

  container "ref-db:${workflow.manifest.version}"

  input:
    path assembly, stageAs: 'out/assembly/*'
    path binning, stageAs: 'out/binning/*'
    path tc, stageAs: 'out/taxonomicClassification/*'
    path fa, stageAs: 'out/functionalAssignment/*'

  output:
    path "out"

  "true"
}
