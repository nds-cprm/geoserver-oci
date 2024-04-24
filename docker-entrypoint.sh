#!/bin/bash
set -ef -o pipefail

GEOSERVER_OPTS="-XX:PerfDataSamplingInterval=500 \
    -XX:SoftRefLRUPolicyMSPerMB=36000 \
    -XX:NewRatio=2 \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -XX:ParallelGCThreads=20 \
    -XX:ConcGCThreads=5 \
    -XX:InitiatingHeapOccupancyPercent=70 \
    -XX:+CMSClassUnloadingEnabled \
    -Dorg.geotools.referencing.forceXY=true \
    -Dorg.geotools.shapefile.datetime=true \
    -Dgeoserver.login.autocomplete=off"

# TODO: Parametrizar CORS
# https://docs.geoserver.org/main/en/user/production/container.html#enable-cors-for-tomcat

# TODO: Parametrizar JMS Cluster

# Geoserver Data dir
GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}"

# Geoserver Interface
GEOSERVER_CONSOLE_DISABLED=${GEOSERVER_CONSOLE_DISABLED:-FALSE}

if [[ "$GEOSERVER_CONSOLE_DISABLED" == "FALSE" ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_CONSOLE_DISABLED=${GEOSERVER_CONSOLE_DISABLED}"
fi

# CSRF Whitelist
GEOSERVER_CSRF_DISABLED=${GEOSERVER_CSRF_DISABLED:-FALSE}
GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_CSRF_DISABLED=${GEOSERVER_CSRF_DISABLED}"

if [[ "$GEOSERVER_CSRF_DISABLED" == "FALSE" &&  -n $GEOSERVER_CSRF_WHITELIST ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_CSRF_WHITELIST=$GEOSERVER_CSRF_WHITELIST"
fi

# Marlin Rendering Engine
GEOSERVER_DISABLE_MARLIN=${GEOSERVER_DISABLE_MARLIN:-FALSE}

if [[ "$GEOSERVER_DISABLE_MARLIN" == "FALSE" ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS \
        -Xbootclasspath/a:$(find $CATALINA_HOME/webapps/geoserver -name marlin*.jar -print -quit)\
        -Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine"
fi

# Geowebcache
if [[ -n "$GEOWEBCACHE_CACHE_DIR" ]]
then
    if [[ -e "$GEOWEBCACHE_CACHE_DIR" && -w "$GEOWEBCACHE_CACHE_DIR" ]]
    then
        GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOWEBCACHE_CACHE_DIR=$GEOWEBCACHE_CACHE_DIR"
    else
        echo "The directory $GEOWEBCACHE_CACHE_DIR is not writable by user"
        exit 1
    fi
fi

# AppSchema Plugin - Properties file
if [[ -r $GEOSERVER_APPSCHEMA_PROPERTIES_FILE ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS -Dapp-schema.properties=$GEOSERVER_APPSCHEMA_PROPERTIES_FILE"
fi

export CATALINA_OPTS="${CATALINA_OPTS} ${GEOSERVER_OPTS}"

exec "$@"

