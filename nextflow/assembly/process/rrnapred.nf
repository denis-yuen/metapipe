process Rrnapred {
  //echo true

  container "rrnapred:${workflow.manifest.version}"

  input:
    tuple FILENAME, path(input, stageAs: 'in/*')

  output:
    path 'out/merged/filtered.fastq.gz', emit: merged_filtered, optional: true
    path 'out/merged/pred16s.fasta', emit: merged_pred16s, optional: true
    path 'out/unmerged_r1/filtered.fastq.gz', emit: unmergedR1_filtered, optional: true
    path 'out/unmerged_r1/pred16s.fasta', emit: unmergedR1_pred16s, optional: true
    path 'out/unmerged_r2/filtered.fastq.gz', emit: unmergedR2_filtered, optional: true
    path 'out/unmerged_r2/pred16s.fasta', emit: unmergedR2_pred16s, optional: true

  shell:
    '''
    set +u
    OUT_SPECIFIC=out/!{FILENAME}
    mkdir -p "$OUT_SPECIFIC"
    /opt/docker/bin/rrnapred -J-Xms$MK_MEM_BYTES -J-Xmx$MK_MEM_LIMIT_BYTES -- \
      -i !{input} --out $OUT_SPECIFIC --cpu $MK_CPU_INT
    '''
}