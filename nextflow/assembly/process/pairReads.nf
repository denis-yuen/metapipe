process PairReads {
  label 'assembly'

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
    case $(echo "!{task.memory}" | cut -d' ' -f2) in
         [gG]B*) UNIT=1073741824;;
         [mM]B*) UNIT=1048576;;
         [kK]B*) UNIT=1024;;
         B*) UNIT=1;;
    esac
    MEMORY=$(( $(echo "!{task.memory}" | cut -d '.' -f1 | cut -d ' ' -f1) * $UNIT ))
    set +x
    /opt/docker/bin/preprocess-reads -J-Xms$MEMORY -J-Xmx$MEMORY -- \
      --r1 !{inputR1} --r2 !{inputR2} --outputDir out --tmpDir /tmp/temp --slices 0
    '''
}