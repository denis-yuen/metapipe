params.slices = 4
params.contigsCutoff = 1000

process PreProcessContigs {

  container "preprocess-contigs:${workflow.manifest.version}"

  input:
    path contigs, stageAs: 'in/*'

  output:
    path 'out/slices/*', emit: slices

  shell:
    '''
    set +u
    if [[ -z $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-J-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    /opt/docker/bin/preprocess-contigs -J-Xms$MK_MEM_BYTES $XMX_FLAG -- --inputPath "!{contigs}" --outPath out/slices --contigsCutoff "!{params.contigsCutoff}" --slices "!{params.slices}"
    '''
}
