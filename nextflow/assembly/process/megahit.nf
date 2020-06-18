params.contigsCutoff = 1000

process Megahit {
  label 'assembly'

  container 'registry.gitlab.com/uit-sfb/genomic-tools/megahit:1.2.9'

  input:
    path inputR1, stageAs: 'in/*'
    path inputR2, stageAs: 'in/*'
    path inputMerged, stageAs: 'in/*'

  output:
    path 'out/contigs.fasta', emit: contigs

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
    mkdir -p out
    #Note: -o must not exist. That is why we use -o /tmp/temp
    set +x
    /app/megahit/bin/megahit -1 !{inputR1} -2 !{inputR2} -r !{inputMerged} -o /tmp/temp \
      --min-contig-len !{params.contigsCutoff} \
      -t !{task.cpus} -m $MEMORY
    RES=$?
    set -x
    cat /tmp/temp/options.json && echo
    if [[ $RES == 0 ]]; then
      #For some reason, symbolic links are not visible as outputs
      cp /tmp/temp/final.contigs.fa out/contigs.fasta
    else
      cat /tmp/temp/log;
      exit $RES;
    fi
    '''
}