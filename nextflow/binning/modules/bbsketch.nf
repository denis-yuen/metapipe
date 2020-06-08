process BbSketch {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/bbmap:38.41'

  input:
    path bin, stageAs: 'inputDir/*'

  output:
    path 'out/*.sketch', emit: bin

  shell:
    '''
    set +u
    BIN_REF=$(basename !{bin} .fasta)
    BIN_OUT="${BIN_REF}.sketch"
    if [[ -z $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    /app/bbmap/sendsketch.sh in=$bin out=out/$BIN_OUT \
      sizemult=10 format=2 mode=single maxfraction=0.1 nt color=f -Xms$MK_MEM_BYTES $XMX_FLAG
    '''
}