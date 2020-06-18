process BbWrap {
  label 'assembly'

  container 'registry.gitlab.com/uit-sfb/genomic-tools/bbmap:38.79'

  input:
    path ref, stageAs: 'in/*'
    path merged, stageAs: 'in/*'
    path trimmedR1, stageAs: 'in/*'
    path trimmedR2, stageAs: 'in/*'

  output:
    path 'out/alignment.sam.gz', emit: alignment
    path 'out/genomes', emit: genomes

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
    set +x
    /app/bbmap/bbwrap.sh ref=!{ref} in=!{trimmedR1},!{merged} in2=!{trimmedR2} \
      out=out/alignment.sam.gz path=/tmp/ \
      kfilter=22 subfilter=15 maxindel=80 qin=33 threads=!{task.cpus} -Xms$MEMORY $XMX_FLAG
    set -x
    #For some reason, symbolic links are not visible as outputs
    cp -r /tmp/ref/genome out/genomes
    '''
}