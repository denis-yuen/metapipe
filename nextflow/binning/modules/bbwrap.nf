process BbWrap {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/bbmap:38.79'

  input:
    path ref, stageAs: 'inputDir/*'
    path merged, stageAs: 'inputDir/*'
    path trimmedR1, stageAs: 'inputDir/*'
    path trimmedR2, stageAs: 'inputDir/*'

  output:
    path 'out/alignment.sam.gz', emit: alignment
    path 'out/genomes', emit: genomes

  shell:
    '''
    set +u
    if [[ -z $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    /app/bbmap/bbwrap.sh ref=!{ref} in=!{trimmedR1},!{merged} in2=!{trimmedR2} \
      out=out/alignment.sam.gz path=/tmp/ \
      kfilter=22 subfilter=15 maxindel=80 qin=33 threads=$MK_CPU_INT -Xms$MK_MEM_BYTES $XMX_FLAG
    #For some reason, symbolic links are not visible as outputs
    cp -r /tmp/ref/genome out/genomes
    '''
}