process BbPileup {
  label 'binning'

  container 'registry.gitlab.com/uit-sfb/genomic-tools/bbmap:38.79'

  input:
    path alignment, stageAs: 'in/*'

  output:
    path 'out/coverage.txt', emit: coverage

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
    if [[ -z $MEMORY ]]; then
      XMX_FLAG="-Xmx$MEMORY"
    fi
    set -x
    /app/bbmap/pileup.sh in=!{alignment} out=out/coverage.txt \
      overwrite=true threads=!{task.cpus} -Xms$MEMORY $XMX_FLAG
    '''
}