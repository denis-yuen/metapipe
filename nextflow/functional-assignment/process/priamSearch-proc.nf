process PriamSearchProc {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/priamsearch:2.0'

  input:
    val refdb
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path 'out/slices/*', emit: priam

  shell:
    '''
    set +u
    DB_PATH="!{refdb}/db/priam/"
    if [[ -z $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    java -Xms$MK_MEM_BYTES $XMX_FLAG -jar /app/priamsearch/PRIAM_search.jar -p "$DB_PATH" -np 1 -pt 0.5 -mp 70 -cc T -cg F -n mp -i "!{input}/cds.prot.fasta" --out /tmp
    mkdir -p out/slices && mv /tmp/PRIAM_mp/ANNOTATION out/slices/!{DATUM}
    '''
}