process Seqprep {
  echo true

  container 'mk-seqprep:1.3.2'

  input:
    path 'inputDir/*'

  output:
    path 'out/data/r1/slices/*/unmerged_r1.fastq.gz', emit: slicesR1
    path 'out/data/r2/slices/*/unmerged_r2.fastq.gz', emit: slicesR2
    path 'out/data/merged.fastq.gz', emit: merged

  shell:
    '''
    set +u
    DATUM=$(ls inputDir)
    inputR1="inputDir/$DATUM/r1.fastq.gz"
    inputR2="inputDir/$DATUM/r2.fastq.gz"
    #seqprep requires output dirs to exist
    mkdir -p $MK_OUT/r1/slices/$DATUM
    mkdir -p $MK_OUT/r2/slices/$DATUM
    $MK_APP -f $inputR1 -r $inputR2 -1 $MK_OUT/r1/slices/$DATUM/unmerged_r1.fastq.gz -2 $MK_OUT/r2/slices/$DATUM/unmerged_r2.fastq.gz -s $MK_OUT/merged.fastq.gz 2>&1
    '''
}