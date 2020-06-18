params.readsCutoff = 75

process TrimmomaticSE {
  label 'assembly'

  container 'registry.gitlab.com/uit-sfb/genomic-tools/trimmomatic:0.39'

  input:
    path 'in/*'

  output:
    path 'out/merged.fastq.gz', emit: merged

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
    if [[ -n $MEMORY ]]; then
      XMX_FLAG="-Xmx$MEMORY"
    fi
    mkdir -p out
    set -x
    java -Xms$MEMORY $XMX_FLAG -jar /app/trimmomatic/trimmomatic.jar \
      SE -threads !{task.cpus} -phred33 in/merged.fastq.gz out/merged.fastq.gz AVGQUAL:20 SLIDINGWINDOW:4:15 MINLEN:!{params.readsCutoff}
    '''
}

process TrimmomaticPE {
  label 'assembly'

  container 'registry.gitlab.com/uit-sfb/genomic-tools/trimmomatic:0.39'

  input:
    path 'in/unmergedR1.fastq.gz'
    path 'in/unmergedR2.fastq.gz'

  output:
    path 'out/unmerged_r1.fastq.gz', emit: unmergedR1
    path 'out/unmerged_r2.fastq.gz', emit: unmergedR2

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
    if [[ -n $MEMORY ]]; then
      XMX_FLAG="-Xmx$MEMORY"
    fi
    mkdir -p out
    set -x
    java -Xms$MEMORY $XMX_FLAG -jar /app/trimmomatic/trimmomatic.jar \
      PE -threads !{task.cpus} -phred33 in/unmergedR1.fastq.gz in/unmergedR2.fastq.gz \
      out/unmerged_r1.fastq.gz /dev/null out/unmerged_r2.fastq.gz /dev/null AVGQUAL:20 SLIDINGWINDOW:4:15 MINLEN:!{params.readsCutoff}
    '''
}