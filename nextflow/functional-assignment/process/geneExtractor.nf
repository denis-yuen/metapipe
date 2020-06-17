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
    case $(echo "!{task.memory}" | cut -d' ' -f2) in
         [gG]B*) UNIT=1073741824;;
         [mM]B*) UNIT=1048576;;
         [kK]B*) UNIT=1024;;
         B*) UNIT=1;;
    esac
    MEMORY=$(( $(echo "!{task.memory}" | awk '{printf "%.0f", $1}') * $UNIT ))
    if !{params.removeIncompleteGenes}; then
      RMV_NON_COMPLETE_FLAG="--removeNonCompleteGenes";
    else
      RMV_NON_COMPLETE_FLAG="";
    fi
    if [[ -z $MEMORY ]]; then
      XMX_FLAG="-J-Xmx$MEMORY"
    fi
    /opt/docker/bin/gene-extractor -J-Xms$MEMORY $XMX_FLAG -- --contigsPath "!{contigs}/contigs.fasta" --mgaOutPath "!{mga}/mga.out" --outPath "out/slices/!{DATUM}" $RMV_NON_COMPLETE_FLAG
    '''
}