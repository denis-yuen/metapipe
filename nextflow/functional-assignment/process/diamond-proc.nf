params.Diamond_sensitivity = 'sensitive'

process DiamondProc {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/diamond:0.9.31'

  input:
    val refdb
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path 'out/slices/*', emit: diamond

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
    case "!{params.Diamond_sensitivity}" in
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
    /app/diamond/diamond blastp -d "$DB_PATH" -q "!{input}/cds.prot.fasta" -o "$OUT_DIR/diamond.out" -k 5 -p $MK_CPU_INT -c 4 -b 1 $SENSITIVE_FLAG --outfmt $OUT_FMT
    '''
}