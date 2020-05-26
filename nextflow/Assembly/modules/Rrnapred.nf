process Rrnapred {
  //echo true

  container 'mk-rrnapred:1.0.0-SNAPSHOT'

  input:
    tuple FILENAME, path(input, stageAs: 'inputDir/*')

  output:


  shell:
    '''
    set +u
    OUT_SPECIFIC="$MK_OUT/!{FILENAME}"
    mkdir -p $OUT_SPECIFIC
    $MK_APP -J-Xms$MK_MEM_BYTES -J-Xmx$MK_MEM_LIMIT_BYTES -- \
      -i !{input} --out $OUT_SPECIFIC --cpu $MK_CPU_INT \
      2>&1
    '''
}