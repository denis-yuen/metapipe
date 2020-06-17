params.toolsCpu = 1
params.maxWorkers = 3
params.precalcService = ''

process InterproscanProc {

  container 'registry.gitlab.com/uit-sfb/genomic-tools/interproscan:5.42-78.0'

  input:
    val refdb
    tuple DATUM, path(input, stageAs: 'in/*')

  output:
    path "out/slices/${DATUM}/interpro.out", emit: interpro

  shell:
    '''
    set +u
    #Interproscan expects the tools at this location
    ln -s "!{refdb}/db/interpro" /app/interpro/data
    OUT_DIR="out/slices/!{DATUM}"
    mkdir -p "$OUT_DIR"
    if [[ "!{params.precalcService}" != "default" ]]; then
       if [[ -z "!{params.precalcService}" ]]; then
         echo "Disabled precalc service"
       else
         echo "Using custom service !{params.precalcService}"
       fi
       sed -r -i 's<(precalculated.match.lookup.service.url=).*<\\1!{params.precalcService}<' /app/interpro/interproscan.properties
    else
       echo "Using EBI precalc service"
    fi
    sed -r -i 's<(.*)(=-c |=-cpu |=--cpu ).*<\\1\\2!{params.toolsCpu}<' /app/interpro/interproscan.properties
    cat /app/interpro/interproscan.properties
    #If XMX is defined, we  replace the the value found in interpro.sh (tricky because there are several instance of -Xmx in the file and we only want to replace the last one)
    #In the end we do not mv interpro.sh.tmp to interpro.sh because that would remove the execute flag (and possibly change some other rights)
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      sed -r "$(sed -n -r '/.*-Xmx[0-9]+[A-Z].*/ =' /app/interpro/interproscan.sh | tail -n 1)"'s/(.*-Xmx)([0-9]+[A-Z])(.*)/\\1'"${MK_MEM_LIMIT_BYTES}"'\\3/' /app/interpro/interproscan.sh > /app/interpro/interproscan.sh.tmp
      cat /app/interpro/interproscan.sh.tmp > /app/interpro/interproscan.sh && rm /app/interpro/interproscan.sh.tmp
    fi
    if [[ -n $MK_MEM_LIMIT_BYTES ]]; then
      sed -r "$(sed -n -r '/.*-Xms[0-9]+[A-Z].*/ =' /app/interpro/interproscan.sh | tail -n 1)"'s/(.*-Xms)([0-9]+[A-Z])(.*)/\\1'"${MK_MEM_BYTES}"'\\3/' /app/interpro/interproscan.sh > /app/interpro/interproscan.sh.tmp
      cat /app/interpro/interproscan.sh.tmp > /app/interpro/interproscan.sh && rm /app/interpro/interproscan.sh.tmp
    fi
    cat /app/interpro/interproscan.sh
    /app/interpro/interproscan.sh -goterms -iprlookup -f tsv --applications TIGRFAM,PRODOM,SMART,ProSiteProfiles,ProSitePatterns,HAMAP,SUPERFAMILY,PRINTS,GENE3D,PIRSF,COILS \
      -i "!{input}/cds.prot.fasta" -o "$OUT_DIR/interpro.out" --tempdir /tmp/temp --cpu !{params.maxWorkers}
    '''
}