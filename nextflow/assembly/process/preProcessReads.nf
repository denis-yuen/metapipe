params.slices = 4

process PreProcessReads {
  container "preprocess-reads:${workflow.manifest.version}"

  input:
    path 'in/*'

  output:
    path 'out/slices/*', emit: slices

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
    FORWARD=($(find in -name "forward.fastq*" \\( -type f -or -type l \\) ))
    if [[ -n $FORWARD ]]; then
      R1_PARAM="--r1 $FORWARD"
    fi
    REVERSE=($(find in -name "reverse.fastq*" \\( -type f -or -type l \\) ))
    if [[ -n $REVERSE ]]; then
      R2_PARAM="--r2 $REVERSE"
    fi
    INTERLEAVED=($(find in -name "interleaved.fastq*" \\( -type f -or -type l \\) ))
    if [[ -n $INTERLEAVED ]]; then
      INTERLEAVED_PARAM="--interleaved $INTERLEAVED"
    fi
    if [[ -n $MEMORY ]]; then
      XMX_FLAG="-J-Xmx$MEMORY"
    fi
    /opt/docker/bin/preprocess-reads -J-Xms$MEMORY $XMX_FLAG -- \
      $R1_PARAM $R2_PARAM $INTERLEAVED_PARAM --outputDir out/slices --tmpDir /tmp --slices !{params.slices}
    '''
}