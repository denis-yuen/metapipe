process PriamSearchProc {

  container 'registry.gitlab.com/uit-sfb/genomic-tools/priamsearch:2.0'

  input:
    val refdb
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path "out/slices/${DATUM}/genomeECs.txt", emit: genomeECs
    path "out/slices/${DATUM}/genomeEnzymes.txt", emit: genomeEnzymes
    path "out/slices/${DATUM}/predictableECs.txt", emit: predictableECs
    path "out/slices/${DATUM}/sequenceECs.txt", emit: sequenceECs

  shell:
    '''
    set +u
    case $(echo "!{task.memory}" | cut -d' ' -f2) in
         [gG]B*) UNIT=1073741824;;
         [mM]B*) UNIT=1048576;;
         [kK]B*) UNIT=1024;;
         B*) UNIT=1;;
    esac
    MEMORY=$(( $(echo "!{task.memory}" | awk '{printf "%.0f", $1}') * $UNIT ))
    DB_PATH="!{refdb}/db/priam/"
    if [[ -z $MEMORY ]]; then
      XMX_FLAG="-Xmx$MEMORY"
    fi
    java -Xms$MEMORY $XMX_FLAG -jar /app/priamsearch/PRIAM_search.jar -p "$DB_PATH" -np 1 -pt 0.5 -mp 70 -cc T -cg F -n mp -i "!{input}/cds.prot.fasta" --out /tmp
    mkdir -p out/slices && mv /tmp/PRIAM_mp/ANNOTATION out/slices/!{DATUM}
    '''
}