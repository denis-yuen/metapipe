process MapseqProc {
  label 'taxonomic_classification'

  container 'registry.gitlab.com/uit-sfb/genomic-tools/mapseq:1.2.6'
  containerOptions = "-v ${params.metapipeDir}/refdb:/refdb"

  input:
    val refdb
    path input, stageAs: 'in/*'

  output:
    path 'out/mapseq.out', emit: taxo

  shell:
    '''
    set +u
    if [[ -n "!{refdb}" ]]; then
      DB_PATH="!{refdb}/db/$(ls "!{refdb}/db")"
      DB="${DB_PATH}/silvamar.fasta ${DB_PATH}/silvamar.tax"
    fi
    mkdir -p out
    set -x
    /app/mapseq/mapseq -nthreads !{task.cpus} !{input} ${DB} > out/mapseq.out
    '''
}