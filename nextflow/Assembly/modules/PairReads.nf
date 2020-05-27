process PairReads {
  //echo true

  container 'registry.gitlab.com/uit-sfb/metapipe/preprocess-reads:0.1.0-SNAPSHOT'

  input:
    path inputR1, stageAs: 'inputDir/r1/*'
    path inputR2, stageAs: 'inputDir/r2/*'

  output:
    path 'out/data/r1.fastq.gz', emit: r1
    path 'out/data/r2.fastq.gz', emit: r2

  shell:
    '''
    set +u
    /opt/docker/bin/preprocess-reads -J-Xms$MK_MEM_BYTES -J-Xmx$MK_MEM_LIMIT_BYTES -- \
      --r1 !{inputR1} --r2 !{inputR2} --outputDir out --tmpDir /tmp/temp --slices 0
    '''
}