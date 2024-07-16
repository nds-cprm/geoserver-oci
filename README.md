# GeoServer Container Image

Uma implementação personalizada do GeoServer, compilado diretamente do código fonte

Autor: Carlos Eduardo Mota

## Build Args
- TOMCAT_IMAGE_TAG=9-jre11-temurin-jammy
- MAVEN_IMAGE_TAG=3.8-eclipse-temurin-11
- MAVEN_OPTS="-Xmx512M"
- ARG GEOSERVER_GIT_URL
- GEOSERVER_VERSION=2.24.2 (testado com 2.17.x, 2.18.x, 2.19.x, 2.21.x, 2.22.x, 2.23.x, 2.24.x, 2.25.x)
- GEOSERVER_DATA_DIR=/srv/geoserver/data
- GEOSERVER_EXTENSIONS=oracle,sqlserver,excel,app-schema,importer,jms-cluster,backup-restore,control-flow
- GEOSERVER_UID=10000
- GEOSERVER_GID=10000

## Environment Variables
- JAVA_OPTS="-server -Djava.awt.headless=true -Xms2G -Xmx3G"
- CATALINA_OPTS=""
- GEOSERVER_VERSION=${GEOSERVER_VERSION}
- GEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}
- GEOSERVER_OPTS="-XX:PerfDataSamplingInterval=500 \
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
- GEOSERVER_CONSOLE_DISABLED=FALSE
- GEOSERVER_CORS_ALLOWED_ORIGINS=""
- GEOSERVER_CSRF_DISABLED=TRUE
- GEOSERVER_DISABLE_MARLIN=FALSE
- GEOWEBCACHE_CACHE_DIR=""
- GEOSERVER_APPSCHEMA_PROPERTIES_FILE

## Add extra fonts
Mount font file on /usr/local/share/fonts
