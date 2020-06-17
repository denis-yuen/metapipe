params.refdbDir = '/refdb'

process DownloadRefDb {

  container "ref-db:${workflow.manifest.version}"

  input:
    val refDb

  output:
    env refdbPath

  shell:
    '''
    set +u
    IFS=':' read -ra DB_SPLIT <<< "!{refDb}"
    DB_NAME="${DB_SPLIT[0]}"
    DB_VERSION="${DB_SPLIT[1]}"
    if [[ -z "$DB_NAME" ]]; then exit 0; fi
    if [[ -z "$DB_VERSION" ]]; then
      DB_VERSION=$($MK_APP -- latest "$DB_NAME")
    fi
    if [[ -z $MK_MEM_LIMIT_BYTES ]]; then
      XMX_FLAG="-J-Xmx$MK_MEM_LIMIT_BYTES"
    fi
    /opt/docker/bin/ref-db -J-Xms$MK_MEM_BYTES $XMX_FLAG -- download -d !{params.refdbDir} ${DB_NAME}=${DB_VERSION}
    refdbPath="!{params.refdbDir}/$DB_NAME/$DB_VERSION"
    '''
}
