process PairReads {
  //echo true

  container 'mk-preprocess-reads:1.0.0-SNAPSHOT'

  input:
    path inputR1, stageAs: 'inputDir/r1/*'
    path inputR2, stageAs: 'inputDir/r2/*'

  output:
    path 'out/data/r1.fastq.gz', emit: r1
    path 'out/data/r2.fastq.gz', emit: r2

  shell:
    '''
    set +u
    $MK_APP -J-Xms$MK_MEM_BYTES -J-Xmx$MK_MEM_LIMIT_BYTES -- \
      --r1 !{inputR1} --r2 !{inputR2} --outputDir $MK_OUT --tmpDir $MK_TMP/tmp --slices 0 \
      2>&1
    '''
}