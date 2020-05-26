params.Megahit_contigsCutoff = 1000

process Megahit {
  //echo true

  container 'mk-megahit:1.2.9'

  input:
    path inputR1, stageAs: 'inputDir/*'
    path inputR2, stageAs: 'inputDir/*'
    path inputMerged, stageAs: 'inputDir/*'

  output:
    path 'out/data/contigs.fasta', emit: contigs

  shell:
    '''
    set +u
    mkdir -p "$MK_OUT"
    CONTIGS_CUTOFF=!{params.Megahit_contigsCutoff}
    #Note: -o must not exist. That is why we use -o $MK_TMP/temp
    $MK_APP -1 !{inputR1} -2 !{inputR2} -r !{inputMerged} -o $MK_TMP/temp \
      --min-contig-len $CONTIGS_CUTOFF \
      -t $MK_CPU_INT -m $MK_MEM_BYTES \
      2>&1
    RES=$?
    cat "$MK_TMP/temp/options.json" && echo
    if [[ $RES == 0 ]]; then
      #For some reason, symbolic links are not visible as outputs
      cp "$MK_TMP/temp/final.contigs.fa" "$MK_OUT/contigs.fasta"
    else
      cat "$MK_TMP/temp/log";
      exit $RES;
    fi
    '''
}