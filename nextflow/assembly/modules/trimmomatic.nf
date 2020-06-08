params.Trimmomatic_readsCutoff = 75

process TrimmomaticSE {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/trimmomatic:0.39'

  input:
    path 'inputDir/*'

  output:
    path 'out/merged.fastq.gz', emit: merged

  shell:
    '''
    set +u
    READS_CUTOFF=!{params.Trimmomatic_readsCutoff}
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    mkdir -p out
    java -Xms$MK_MEM_BYTES $XMX_FLAG -jar /app/trimmomatic/trimmomatic.jar \
      SE -threads $MK_CPU_INT -phred33 inputDir/merged.fastq.gz out/merged.fastq.gz AVGQUAL:20 SLIDINGWINDOW:4:15 MINLEN:$READS_CUTOFF
    '''
}

process TrimmomaticPE {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/trimmomatic:0.39'

  input:
    path 'inputDir/unmergedR1.fastq.gz'
    path 'inputDir/unmergedR2.fastq.gz'

  output:
    path 'out/unmerged_r1.fastq.gz', emit: unmergedR1
    path 'out/unmerged_r2.fastq.gz', emit: unmergedR2

  shell:
    '''
    set +u
    READS_CUTOFF=!{params.Trimmomatic_readsCutoff}
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    mkdir -p out
    java -Xms$MK_MEM_BYTES $XMX_FLAG -jar /app/trimmomatic/trimmomatic.jar \
      PE -threads $MK_CPU_INT -phred33 inputDir/unmergedR1.fastq.gz inputDir/unmergedR2.fastq.gz \
      out/unmerged_r1.fastq.gz /dev/null out/unmerged_r2.fastq.gz /dev/null AVGQUAL:20 SLIDINGWINDOW:4:15 MINLEN:$READS_CUTOFF
    '''
}