process BbSketch {
  label 'assembly'
  tag "${bin.baseName}"

  container 'registry.gitlab.com/uit-sfb/genomic-tools/bbmap:38.79'

  input:
    path bin, stageAs: 'in/*'

  output:
    path 'out/*.sketch', emit: bin

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
    BIN_REF=$(basename !{bin} .fasta)
    BIN_OUT="${BIN_REF}.sketch"
    if [[ -z $MEMORY ]]; then
      XMX_FLAG="-Xmx$MEMORY"
    fi
    set -x
    /app/bbmap/sendsketch.sh in=!{bin} out=out/$BIN_OUT \
      sizemult=10 format=2 mode=single maxfraction=0.1 nt color=f -Xms$MEMORY $XMX_FLAG
    '''
}