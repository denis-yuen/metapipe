process Rrnapred {
  //echo true

  container 'mk-rrnapred:1.0.0-SNAPSHOT'

  input:
    tuple FILENAME, path(input, stageAs: 'inputDir/*')

  output:
    path 'out/data/merged/filtered.fastq.gz', emit: merged_filtered, optional: true
    path 'out/data/merged/pred16s.fasta', emit: merged_pred16s, optional: true
    path 'out/data/unmerged_r1/filtered.fastq.gz', emit: unmergedR1_filtered, optional: true
    path 'out/data/unmerged_r1/pred16s.fasta', emit: unmergedR1_pred16s, optional: true
    path 'out/data/unmerged_r2/filtered.fastq.gz', emit: unmergedR2_filtered, optional: true
    path 'out/data/unmerged_r2/pred16s.fasta', emit: unmergedR2_pred16s, optional: true

  shell:
    '''
    set +u
    OUT_SPECIFIC="$MK_OUT/!{FILENAME}"
    mkdir -p $OUT_SPECIFIC
    $MK_APP -J-Xms$MK_MEM_BYTES -J-Xmx$MK_MEM_LIMIT_BYTES -- \
      -i !{input} --out $OUT_SPECIFIC --cpu $MK_CPU_INT \
      2>&1
    ls
    '''
}