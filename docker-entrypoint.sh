#!/usr/bin/env bash
set -ef -o pipefail

GEOSERVER_OPTS="-Djava.awt.headless=true \
    -server \
    -XX:PerfDataSamplingInterval=500 \
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
    -Dgeoserver.login.autocomplete=off \
    -DGEOSERVER_CONSOLE_DISABLED=${GEOSERVER_CONSOLE_DISABLED:-FALSE} \
    -DGEOSERVER_CSRF_DISABLED=${GEOSERVER_CSRF_DISABLED:-FALSE}"

# CSRF Whitelist
if [[ "$GEOSERVER_CSRF_DISABLED" == "FALSE" && -n $GEOSERVER_CSRF_WHITELIST ]]
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

# AppSchema Plugin - Properties file
if [[ -n $GEOSERVER_APPSCHEMA_PROPERTIES_FILE ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS -Dapp-schema.properties=$GEOSERVER_APPSCHEMA_PROPERTIES_FILE"
fi

exec env CATALINA_OPTS="${CATALINA_OPTS} ${GEOSERVER_OPTS}" "$@"
