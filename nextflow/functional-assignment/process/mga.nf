process Mga {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/mga:1'

  input:
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path "out/slices/${DATUM}", emit: mga

  shell:
    '''
    set +u
    OUT_DIR="out/slices/!{DATUM}"
    mkdir -p "$OUT_DIR" #requires output dir to exist
    if [[ -s !{input}/contigs.fasta ]]; then
      /app/mga/mga_linux_ia64 "!{input}/contigs.fasta" > "$OUT_DIR/mga.out"
    else
      #Deal with empty input here as mga throws Segmentation fault otherwise
      echo "Empty input"
    fi
    '''
}