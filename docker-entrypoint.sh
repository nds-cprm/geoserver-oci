#!/usr/bin/env bash
set -ef -o pipefail

GEOSERVER_OPTS="-Djava.awt.headless=true -server \
    -XX:PerfDataSamplingInterval=500 -Dorg.geotools.referencing.forceXY=true \
    -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:NewRatio=2 \
    -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=20 -XX:ConcGCThreads=5 \
    -XX:InitiatingHeapOccupancyPercent=70 -XX:+CMSClassUnloadingEnabled \
    -Dorg.geotools.shapefile.datetime=true -Dgeoserver.login.autocomplete=off \
    -DGEOSERVER_CONSOLE_DISABLED=${GEOSERVER_CONSOLE_DISABLED:-FALSE} \
    -Xbootclasspath/a:$(find $CATALINA_HOME/webapps/geoserver -name marlin*.jar -print -quit) \
    -Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine \
    -DGEOSERVER_CSRF_DISABLED=${GEOSERVER_CSRF_DISABLED:-TRUE}"

if [[ -n $GEOSERVER_APPSCHEMA_PROPERTIES_FILE ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS -Dapp-schema.properties=$GEOSERVER_APPSCHEMA_PROPERTIES_FILE"
fi

exec env CATALINA_OPTS="${CATALINA_OPTS} ${GEOSERVER_OPTS}" "$@"
