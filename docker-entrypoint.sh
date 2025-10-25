#!/bin/bash
set -ef -o pipefail

if [[ -z "$JAVA_OPTS" ]]
then
    export JAVA_OPTS="-server -Djava.awt.headless=true -Xms2G -Xmx4G"
fi

if [[ -z "$CATALINA_OPTS" ]]
then 
    CATALINA_OPTS="-XX:PerfDataSamplingInterval=500 \
        -XX:SoftRefLRUPolicyMSPerMB=36000 \
        -XX:NewRatio=2 \
        -XX:+UseG1GC \
        -XX:+UseStringDeduplication \
        -XX:InitiatingHeapOccupancyPercent=70"
fi

if [[ -z "$GEOSERVER_OPTS" ]]
then
    GEOSERVER_OPTS="-XX:PerfDataSamplingInterval=500 \
        -Dorg.geotools.referencing.forceXY=true \
        -Dorg.geotools.shapefile.datetime=true \
        -Dgeoserver.login.autocomplete=off \
        -Doracle.jdbc.timezoneAsRegion=false"
fi

# CORS
# # Geoserver >= 2.27: https://discourse.osgeo.org/t/org-geoserver-filters-xframeoptionsfilter-lost/146457
TPL=$(envsubst < webapps/geoserver/WEB-INF/templates/cross-origin.xml.envsubst)
sed "/<\/web-app>/i $(echo $TPL)" webapps/geoserver/WEB-INF/web.xml > /tmp/web.xml
unset TPL
cp /tmp/web.xml webapps/geoserver/WEB-INF/web.xml
rm -rf /tmp/web.xml

# TODO: Parametrizar JMS Cluster

# Copy
echo "Copying Geoserver default config if empty"
find ./webapps/geoserver/data -maxdepth 1 -type f -name "*.xml" | xargs cp -t $GEOSERVER_DATA_DIR

# Geoserver Data dir
GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}"

# Geoserver Interface
GEOSERVER_CONSOLE_DISABLED=${GEOSERVER_CONSOLE_DISABLED:-false}

if [[ "$GEOSERVER_CONSOLE_DISABLED" == "true" ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_CONSOLE_DISABLED=${GEOSERVER_CONSOLE_DISABLED}"
fi

# CSRF Whitelist
GEOSERVER_CSRF_DISABLED=${GEOSERVER_CSRF_DISABLED:-false}
GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_CSRF_DISABLED=${GEOSERVER_CSRF_DISABLED}"

if [[ "$GEOSERVER_CSRF_DISABLED" == "false" &&  -n $GEOSERVER_CSRF_WHITELIST ]]
then
    GEOSERVER_OPTS="$GEOSERVER_OPTS -DGEOSERVER_CSRF_WHITELIST=$GEOSERVER_CSRF_WHITELIST"
fi

# Marlin Rendering Engine
GEOSERVER_DISABLE_MARLIN=${GEOSERVER_DISABLE_MARLIN:-false}

if [[ "$GEOSERVER_DISABLE_MARLIN" == "false" ]]
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
