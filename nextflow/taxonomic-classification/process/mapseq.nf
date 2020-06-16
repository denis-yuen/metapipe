process Mapseq {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/mapseq:1.2.6'

  input:
    val refdb
    path inputMerged, stageAs: 'in/merged'
    path inputR1, stageAs: 'in/unmerged_r1'
    path inputR2, stageAs: 'in/unmerged_r2'

  output:
    path 'out/mapseq.out', emit: taxo

  shell:
    '''
    set +u
    if [[ -n "!{refdb}" ]]; then
      DB_PATH="!{refdb}/db/$(ls "!{refdb}/db")"
      DB="${DB_PATH}/silvamar.fasta ${DB_PATH}/silvamar.tax"
    fi
    cat !{inputMerged} !{inputR1} !{inputR2} > /tmp/combined.fasta
    mkdir -p out
    /app/mapseq/mapseq -nthreads $MK_CPU_INT /tmp/combined.fasta ${DB} > out/mapseq.out
    '''
}