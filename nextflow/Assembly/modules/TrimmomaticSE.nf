params.TrimmomaticSE_readsCutoff = 75

process TrimmomaticSE {
  echo true

  container 'mk-trimmomatic:0.39'

  input:
    path 'inputDir/*'

  output:
    path 'out/data/merged.fastq.gz', emit: merged

  shell:
    '''
    set +u
    READS_CUTOFF=!{params.TrimmomaticSE_readsCutoff}
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    mkdir -p "$MK_OUT"
    $MK_APP -Xms$MK_MEM_BYTES $XMX_FLAG -- SE -threads $MK_CPU_INT -phred33 inputDir/merged.fastq.gz $MK_OUT/merged.fastq.gz AVGQUAL:20 SLIDINGWINDOW:4:15 MINLEN:$READS_CUTOFF
    '''
}