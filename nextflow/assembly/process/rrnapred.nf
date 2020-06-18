process Rrnapred {
  label 'assembly'
  tag "${FILENAME}"

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
    case $(echo "!{task.memory}" | cut -d' ' -f2) in
         [gG]B*) UNIT=1073741824;;
         [mM]B*) UNIT=1048576;;
         [kK]B*) UNIT=1024;;
         B*) UNIT=1;;
    esac
    MEMORY=$(( $(echo "!{task.memory}" | cut -d '.' -f1 | cut -d ' ' -f1) * $UNIT ))
    OUT_SPECIFIC=out/!{FILENAME}
    mkdir -p "$OUT_SPECIFIC"
    set +x
    /opt/docker/bin/rrnapred -J-Xms$MEMORY -J-Xmx$MEMORY -- \
      -i !{input} --out $OUT_SPECIFIC --cpu !{task.cpus}
    '''
}