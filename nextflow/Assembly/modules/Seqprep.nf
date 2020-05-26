process Seqprep {
  //echo true

  container 'mk-seqprep:1.3.2'

  input:
    tuple DATUM, path(input, stageAs: 'inputDir/*')

  output:
    path 'out/data/slices/*/unmerged_r1.fastq.gz', emit: unmergedR1
    path 'out/data/slices/*/unmerged_r2.fastq.gz', emit: unmergedR2
    path 'out/data/slices/*/merged.fastq.gz', emit: merged

  shell:
    '''
    set +u
    OUT_DIR="$MK_OUT/slices/!{DATUM}"
    mkdir -p "$OUT_DIR" #seqprep requires output dir to exist
    $MK_APP \
      -f !{input}/r1.fastq.gz \
      -r !{input}/r2.fastq.gz \
      -1 "$OUT_DIR/unmerged_r1.fastq.gz" \
      -2 "$OUT_DIR/unmerged_r2.fastq.gz" \
      -s "$OUT_DIR/merged.fastq.gz" \
      2>&1
    '''
}