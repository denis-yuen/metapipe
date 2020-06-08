params.Megahit_contigsCutoff = 1000

process Megahit {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/megahit:1.2.9'

  input:
    path inputR1, stageAs: 'inputDir/*'
    path inputR2, stageAs: 'inputDir/*'
    path inputMerged, stageAs: 'inputDir/*'

  output:
    path 'out/contigs.fasta', emit: contigs

  shell:
    '''
    set +u
    mkdir -p out
    CONTIGS_CUTOFF=!{params.Megahit_contigsCutoff}
    #Note: -o must not exist. That is why we use -o /tmp/temp
    /app/megahit/bin/megahit -1 !{inputR1} -2 !{inputR2} -r !{inputMerged} -o /tmp/temp \
      --min-contig-len $CONTIGS_CUTOFF \
      -t $MK_CPU_INT -m $MK_MEM_BYTES
    RES=$?
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