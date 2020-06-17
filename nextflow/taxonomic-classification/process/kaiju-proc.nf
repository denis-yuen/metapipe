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
    case $(echo "!{task.memory}" | cut -d' ' -f2) in
         [gG]B*) UNIT=1073741824;;
         [mM]B*) UNIT=1048576;;
         [kK]B*) UNIT=1024;;
         B*) UNIT=1;;
    esac
    MEMORY=$(( $(echo "!{task.memory}" | awk '{printf "%.0f", $1}') * $UNIT ))
    DB_PATH="!{refdb}/db/kaiju/$(ls "!{refdb}/db/kaiju")"
    DB_SIZE=$(stat --printf="%s" $DB_PATH/*.fmi)
    if [[ -n $MEMORY ]]; then
      if [[ $MEMORY < $DB_SIZE ]]; then
        echo "Kaiju needs to fit the whole database ($DB_SIZE bytes) into memory. Please increase the memory limit (currently only $MEMORY bytes)."
        exit 1
      fi
    fi
    mkdir -p out
    /app/kaiju/kaiju -t $DB_PATH/nodes.dmp -f $DB_PATH/*.fmi \
      -i !{input} -o out/kaiju.out -z !{task.cpus}
    '''
}