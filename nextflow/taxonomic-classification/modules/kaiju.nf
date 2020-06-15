process Kaiju {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/kaiju:1.7.3'
  containerOptions '-e MK_MEM_BYTES=20000000000 -e MK_MEM_LIMIT_BYTES=20000000000'

  input:
    val refdb
    path inputMerged, stageAs: 'inputDir/merged'
    path inputR1, stageAs: 'inputDir/unmerged_r1'
    path inputR2, stageAs: 'inputDir/unmerged_r2'

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
    cat $inputMerged $inputR1 $inputR2 > /tmp/combined.fastq
    mkdir -p out
    /app/kaiju/kaiju -t $DB_PATH/nodes.dmp -f $DB_PATH/*.fmi \
      -i /tmp/combined.fastq -o out/kaiju.out -z $MK_CPU_INT
    '''
}