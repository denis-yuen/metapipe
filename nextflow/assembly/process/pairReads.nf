process PairReads {

  container "preprocess-reads:${workflow.manifest.version}"

  input:
    path inputR1, stageAs: 'in/r1/*'
    path inputR2, stageAs: 'in/r2/*'

  output:
    path 'out/r1.fastq.gz', emit: r1
    path 'out/r2.fastq.gz', emit: r2

  shell:
    '''
    set +u
    /opt/docker/bin/preprocess-reads -J-Xms$MK_MEM_BYTES -J-Xmx$MK_MEM_LIMIT_BYTES -- \
      --r1 !{inputR1} --r2 !{inputR2} --outputDir out --tmpDir /tmp/temp --slices 0
    '''
}