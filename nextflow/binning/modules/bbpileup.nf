process BbPileup {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/bbmap:38.79'

  input:
    path alignment, stageAs: 'in/*'

  output:
    path 'out/coverage.txt', emit: coverage

  shell:
    '''
    set +u
    if [[ -z $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    /app/bbmap/pileup.sh in=!{alignment} out=out/coverage.txt \
      overwrite=true threads=$MK_CPU_INT -Xms$MK_MEM_BYTES $XMX_FLAG
    '''
}