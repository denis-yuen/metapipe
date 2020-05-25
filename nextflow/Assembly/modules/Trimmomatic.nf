params.Trimmomatic_readsCutoff = 75

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
    READS_CUTOFF=!{params.Trimmomatic_readsCutoff}
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    mkdir -p "$MK_OUT"
    $MK_APP -Xms$MK_MEM_BYTES $XMX_FLAG -- SE -threads $MK_CPU_INT -phred33 inputDir/merged.fastq.gz $MK_OUT/merged.fastq.gz AVGQUAL:20 SLIDINGWINDOW:4:15 MINLEN:$READS_CUTOFF 2>&1
    '''
}

process TrimmomaticPE {
  echo true

  container 'mk-trimmomatic:0.39'

  input:
    path 'inputDir/*'
    path 'inputDir/*'

  output:
    path 'out/data/unmerged_r1.fastq.gz', emit: unmergedR1
    path 'out/data/unmerged_r2.fastq.gz', emit: unmergedR2

  shell:
    '''
    set +u
    READS_CUTOFF=!{params.Trimmomatic_readsCutoff}
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    mkdir -p "$MK_OUT"
    $MK_APP -Xms$MK_MEM_BYTES $XMX_FLAG -- \
      PE -threads $MK_CPU_INT -phred33 inputDir/unmergedR1.fastq.gz inputDir/unmergedR2.fastq.gz \
      $MK_OUT/unmerged_r1.fastq.gz /dev/null $MK_OUT/unmerged_r2.fastq.gz /dev/null AVGQUAL:20 SLIDINGWINDOW:4:15 MINLEN:$READS_CUTOFF 2>&1
    '''
}