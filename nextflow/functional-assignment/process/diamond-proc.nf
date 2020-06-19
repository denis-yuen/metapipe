params.sensitivity = 'sensitive'

process DiamondProc {
  label 'functional_assignment'
  tag "$DATUM"

  container 'registry.gitlab.com/uit-sfb/genomic-tools/diamond:0.9.31'
  containerOptions = "-v ${params.metapipeDir}/refdb:/refdb"

  memory = '8 GB'

  input:
    val refdb
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path "out/slices/${DATUM}/diamond.out", emit: diamond

  shell:
    '''
    set +u
    DB_NAME=$(basename $(dirname "!{refdb}"))
    if [[ "$DB_NAME" == "diamond-uniref50" ]]; then
      DB_SUFFIX=uniprot/uniref50
      OUT_FMT="6"
    else
      DB_SUFFIX=marref/proteins
      OUT_FMT="6 qseqid sseqid stitle pident length mismatch gapopen qstart qend sstart send evalue bitscore"
    fi
    DB_PATH="!{refdb}/db/diamond/$DB_SUFFIX/nr.dmnd"
    OUT_DIR="out/slices/!{DATUM}"
    mkdir -p "$OUT_DIR"
    case "!{params.sensitivity}" in
      sensitive)
        SENSITIVE_FLAG="--sensitive"
        ;;
      more-sensitive)
        SENSITIVE_FLAG="--more-sensitive"
        ;;
      *)
        SENSITIVE_FLAG=""
        ;;
    esac
    set -x
    /app/diamond/diamond blastp -d "$DB_PATH" -q "!{input}/cds.prot.fasta" -o "$OUT_DIR/diamond.out" -k 5 -p !{task.cpus} -c 4 -b 1 $SENSITIVE_FLAG --outfmt $OUT_FMT
    '''
}