params.contigsCutoff = 1000

process PreProcessContigs {
  label 'functional_assignment'

  container "preprocess-contigs:${workflow.manifest.version}"

  ext.slices = 1

  input:
    path contigs, stageAs: 'in/*'

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
    if [[ -z $MEMORY ]]; then
      XMX_FLAG="-J-Xmx$MEMORY"
    fi
    set -x
    /opt/docker/bin/preprocess-contigs -J-Xms$MEMORY $XMX_FLAG -- --inputPath "!{contigs}" --outPath out/slices --contigsCutoff "!{params.contigsCutoff}" --slices "!{task.ext.slices}"
    '''
}
