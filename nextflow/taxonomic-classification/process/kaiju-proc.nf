process KaijuProc {
  label 'taxonomic_classification'

  container 'registry.gitlab.com/uit-sfb/genomic-tools/kaiju:1.7.3'
  containerOptions = "-v ${params.metapipeDir}/refdb:/refdb"
  memory { "$dbsize".toLong().B + 1.GB }

  input:
    val refdb
    path input, stageAs: 'in/*'
    val dbsize

  output:
    path 'out/kaiju.out', emit: taxo

  shell:
    '''
    set +u
    mkdir -p out
    DB_PATH="!{refdb}/db/kaiju/$(ls "!{refdb}/db/kaiju")"
    set -x
    /app/kaiju/kaiju -t $DB_PATH/nodes.dmp -f $DB_PATH/*.fmi \
      -i !{input} -o out/kaiju.out -z !{task.cpus}
    '''
}