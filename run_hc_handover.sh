#!/bin/bash --

function die {
    echo $1 1>&2
    exit $2
}

function usage {
    die "Usage: $0 -s|--src src_srv -d|--dbname test_db [-l|--live live_srv] [-p|--production production_db_srv] [-c|--compara compara_master_srv] [-g|--group hc_group] [-v|--verbose]" 1
}

function msg {
    echo $(date +"%Y/%m/%d %H:%M:%S") $1
}

TEMP=`getopt -o d:s:l:p:c:g:o:v --long dbname:,src:,live:,production:,compara:,group:,outfile:,verbose -n 'run_hc_handover.sh' -- "$@"`

if [ $? != 0 ] ; then 
    usage; 
fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

LIVE=mysql-ensembl-mirror
COMPARA=mysql-ens-compara-prod-1
PROD=mysql-ens-sta-1
SRC=
VERBOSE=
DBNAME=
GROUP=
while true; do
    case "$1" in
        -o | --outfile ) VERBOSE=" --outfile $2"; shift 2;;
        -v | --verbose ) VERBOSE=" --verbose"; shift ;;
        -d | --dbname ) DBNAME="$2"; shift 2;;
        -s | --src ) SRC="$2"; shift 2;;
        -l | --live ) LIVE="$2"; shift 2;;
        -p | --production ) PROD="$2"; shift 2;;
        -c | --compara ) COMPARA="$2"; shift 2;;
        -g | --group ) GROUP="$2"; shift 2;;
        -- ) shift; break ;;
        * ) usage ;;
    esac
done

if [ -z "$SRC" ] || [ -z "$DBNAME" ]; then
    usage
fi

echo $DBNAME
if [ -z "$GROUP" ]; then
    if [[ $DBNAME =~ .*_core_.* ]]; then
        GROUP="GenebuildHandover"
    elif [[ $DBNAME =~ .*_variation_.* ]]; then
        GROUP="VariationRelease"
    elif [[ $DBNAME =~ .*_compara_.* ]]; then
        GROUP="ComparaRelease"
    elif [[ $DBNAME =~ .*_funcgen_.* ]]; then
        GROUP="FuncgenRelease"
    else
        die "Type for database $DBNAME not recognised" 2
    fi
fi
if [ ! -e "./perlcode" ]; then
    die "./perlcode directory not found" 4
fi

RELEASE=$(perl -MBio::EnsEMBL::ApiVersion -e "print software_version()")
msg "Running tests on Ensembl $RELEASE"

command="java -jar ./target/healthchecks-jar-with-dependencies.jar --dbname $DBNAME $($SRC details script) $($LIVE details script_secondary_) $($COMPARA details script_compara_) $($PROD details script_prod_) -g $GROUP $VERBOSE --release $RELEASE"
msg "Building healthcheck jar"
mvn package >& mvn.out || {
    die "Could not build jar" 8
}
if [ ! -e "$JAR" ]; then
    die "$JAR not found " 16
fi


msg "Running healthchecks"
$command
