process Seqprep {
  label 'assembly'
  tag "$DATUM"

  container 'registry.gitlab.com/uit-sfb/genomic-tools/seqprep:1.3.2'

  input:
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path "out/slices/${DATUM}/unmerged_r1.fastq.gz", emit: unmergedR1
    path "out/slices/${DATUM}/unmerged_r2.fastq.gz", emit: unmergedR2
    path "out/slices/${DATUM}/merged.fastq.gz", emit: merged

  shell:
    '''
    set +u
    OUT_DIR="out/slices/!{DATUM}"
    mkdir -p "$OUT_DIR" #seqprep requires output dir to exist
    set -x
    /app/seqprep/SeqPrep \
      -f !{input}/r1.fastq.gz \
      -r !{input}/r2.fastq.gz \
      -1 "$OUT_DIR/unmerged_r1.fastq.gz" \
      -2 "$OUT_DIR/unmerged_r2.fastq.gz" \
      -s "$OUT_DIR/merged.fastq.gz"
    '''
}
