params.removeIncompleteGenes = false

process GeneExtractor {

  container "gene-extractor:${workflow.manifest.version}"

  input:
    tuple DATUM, path(contigs, stageAs: 'in/contigs/*'), path(mga, stageAs: 'in/mga/*')

  output:
    path "out/slices/${DATUM}", emit: cds

  shell:
    '''
    set +u
    if !{params.removeIncompleteGenes}; then
      RMV_NON_COMPLETE_FLAG="--removeNonCompleteGenes";
    else
      RMV_NON_COMPLETE_FLAG="";
    fi
    if [[ -z $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-J-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    /opt/docker/bin/gene-extractor -J-Xms$MK_MEM_BYTES $XMX_FLAG -- --contigsPath "!{contigs}/contigs.fasta" --mgaOutPath "!{mga}/mga.out" --outPath "out/slices/!{DATUM}" $RMV_NON_COMPLETE_FLAG
    '''
}