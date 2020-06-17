process KaijuProc {

  container 'registry.gitlab.com/uit-sfb/genomic-tools/kaiju:1.7.3'
  label 'kaiju'

  input:
    val refdb
    path input, stageAs: 'in/*'

  output:
    path 'out/kaiju.out', emit: taxo

  shell:
    '''
    set +u
    DB_PATH="!{refdb}/db/kaiju/$(ls "!{refdb}/db/kaiju")"
    DB_SIZE=$(stat --printf="%s" $DB_PATH/*.fmi)
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      if [[ $MK_MEM_LIMIT_BYTES < $DB_SIZE ]]; then
        echo "Kaiju needs to fit the whole database ($DB_SIZE bytes) into memory. Please increase the memory limit (currently only $MK_MEM_LIMIT_BYTES bytes)."
        exit 1
      fi
    fi
    mkdir -p out
    /app/kaiju/kaiju -t $DB_PATH/nodes.dmp -f $DB_PATH/*.fmi \
      -i !{input} -o out/kaiju.out -z $MK_CPU_INT
    '''
}