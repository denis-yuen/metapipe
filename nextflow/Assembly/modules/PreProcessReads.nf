params.PreProcessReads_slices = 4

process PreProcessReads {
  //echo true

  container 'mk-preprocess-reads:1.0.0-SNAPSHOT'

  input:
    path 'inputDir/*'

  output:
    path 'out/data/slices/*', emit: slices

  shell:
    '''
    set +u
    SLICES=!{params.PreProcessReads_slices}
    FORWARD=($(find inputDir -name "forward.fastq*" -type f -or -type l))
    if [[ -n $FORWARD ]]; then
      R1_PARAM="--r1 $FORWARD"
    fi
    REVERSE=($(find inputDir -name "reverse.fastq*" -type f -or -type l))
    if [[ -n $REVERSE ]]; then
      R2_PARAM="--r2 $REVERSE"
    fi
    INTERLEAVED=($(find inputDir -name "interleaved.fastq*" -type f -or -type l))
    if [[ -n $INTERLEAVED ]]; then
      INTERLEAVED_PARAM="--interleaved $INTERLEAVED"
    fi
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-J-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    $MK_APP -J-Xms$MK_MEM_BYTES $XMX_FLAG -- $R1_PARAM $R2_PARAM $INTERLEAVED_PARAM --outputDir $MK_OUT/slices --tmpDir $MK_TMP --slices $SLICES
    '''
}