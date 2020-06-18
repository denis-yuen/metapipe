process InterproscanProc {
  label 'functional_assignment'
  tag "$DATUM"

  container 'registry.gitlab.com/uit-sfb/genomic-tools/interproscan:5.42-78.0'
  containerOptions = "-v ${params.metapipeDir}/refdb:/refdb"

  input:
    val refdb
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path "out/slices/${DATUM}/interpro.out", emit: interpro

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
    MAX_WORKERS=$(( (!{task.cpus} - 1) / !{task.ext.toolsCpu} ))
    if [[ $MAX_WORKERS < 1  ]]; then MAX_WORKERS=1; fi
    #Interproscan expects the tools at this location
    ln -s "!{refdb}/db/interpro" /app/interpro/data
    OUT_DIR="out/slices/!{DATUM}"
    mkdir -p "$OUT_DIR"
    if [[ "!{task.ext.precalcService}" != "default" ]]; then
       if [[ -z "!{task.ext.precalcService}" ]]; then
         echo "Disabled precalc service"
       else
         echo "Using custom service !{task.ext.precalcService}"
       fi
       sed -r -i 's<(precalculated.match.lookup.service.url=).*<\\1!{task.ext.precalcService}<' /app/interpro/interproscan.properties
    else
       echo "Using EBI precalc service"
    fi
    sed -r -i 's<(.*)(=-c |=-cpu |=--cpu ).*<\\1\\2!{task.ext.toolsCpu}<' /app/interpro/interproscan.properties
    cat /app/interpro/interproscan.properties
    #If XMX is defined, we  replace the the value found in interpro.sh (tricky because there are several instance of -Xmx in the file and we only want to replace the last one)
    #In the end we do not mv interpro.sh.tmp to interpro.sh because that would remove the execute flag (and possibly change some other rights)
    if [[ -n $MEMORY ]]; then
      sed -r "$(sed -n -r '/.*-Xmx[0-9]+[A-Z].*/ =' /app/interpro/interproscan.sh | tail -n 1)"'s/(.*-Xmx)([0-9]+[A-Z])(.*)/\\1'"${MEMORY}"'\\3/' /app/interpro/interproscan.sh > /app/interpro/interproscan.sh.tmp
      cat /app/interpro/interproscan.sh.tmp > /app/interpro/interproscan.sh && rm /app/interpro/interproscan.sh.tmp
    fi
    if [[ -n $MEMORY ]]; then
      sed -r "$(sed -n -r '/.*-Xms[0-9]+[A-Z].*/ =' /app/interpro/interproscan.sh | tail -n 1)"'s/(.*-Xms)([0-9]+[A-Z])(.*)/\\1'"${MEMORY}"'\\3/' /app/interpro/interproscan.sh > /app/interpro/interproscan.sh.tmp
      cat /app/interpro/interproscan.sh.tmp > /app/interpro/interproscan.sh && rm /app/interpro/interproscan.sh.tmp
    fi
    cat /app/interpro/interproscan.sh
    set +x
    /app/interpro/interproscan.sh -goterms -iprlookup -f tsv --applications TIGRFAM,PRODOM,SMART,ProSiteProfiles,ProSitePatterns,HAMAP,SUPERFAMILY,PRINTS,GENE3D,PIRSF,COILS \
      -i "!{input}/cds.prot.fasta" -o "$OUT_DIR/interpro.out" --tempdir /tmp/temp --cpu $MAX_WORKERS
    '''
}