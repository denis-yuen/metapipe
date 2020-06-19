process PreProcessReads {
  label 'assembly'

  container "preprocess-reads:${workflow.manifest.version}"

  ext.slices = 1

  input:
    path input, stageAs: 'in/*'

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
    MEMORY=$(( $(echo "!{task.memory}" | cut -d '.' -f1 | cut -d ' ' -f1) * $UNIT ))
    if [[ "!{input[1]}" != "null" ]]; then
      R1_PARAM="--r1 !{input[0]}"
      R2_PARAM="--r2 !{input[1]}"
    else
      INTERLEAVED_PARAM="--interleaved !{input[3]}"
    fi
    if [[ -n $MEMORY ]]; then
      XMX_FLAG="-J-Xmx$MEMORY"
    fi
    set -x
    /opt/docker/bin/preprocess-reads -J-Xms$MEMORY $XMX_FLAG -- \
      $R1_PARAM $R2_PARAM $INTERLEAVED_PARAM --outputDir out/slices --tmpDir /tmp --slices !{task.ext.slices}
    '''
}