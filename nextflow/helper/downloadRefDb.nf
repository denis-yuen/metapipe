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
    case $(echo "!{task.memory}" | cut -d' ' -f2) in
         [gG]B*) UNIT=1073741824;;
         [mM]B*) UNIT=1048576;;
         [kK]B*) UNIT=1024;;
         B*) UNIT=1;;
    esac
    MEMORY=$(( $(echo "!{task.memory}" | awk '{printf "%.0f", $1}') * $UNIT ))
    IFS=':' read -ra DB_SPLIT <<< "!{refDb}"
    DB_NAME="${DB_SPLIT[0]}"
    DB_VERSION="${DB_SPLIT[1]}"
    if [[ -z "$DB_NAME" ]]; then exit 0; fi
    if [[ -z "$DB_VERSION" ]]; then
      DB_VERSION=$(/opt/docker/bin/ref-db -- latest "$DB_NAME")
    fi
    if [[ -z $MEMORY ]]; then
      XMX_FLAG="-J-Xmx$MEMORY"
    fi
    /opt/docker/bin/ref-db -J-Xms$MEMORY $XMX_FLAG -- download -d !{params.refdbDir} ${DB_NAME}=${DB_VERSION}
    refdbPath="!{params.refdbDir}/$DB_NAME/$DB_VERSION"
    '''
}
