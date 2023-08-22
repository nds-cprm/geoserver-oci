# GeoServer Container Image

Uma implementação personalizada do GeoServer, compilado diretamente do código fonte

Autor: Carlos Eduardo Mota

## Build Args
- TOMCAT_IMAGE_TAG=9-jre11-temurin-jammy
- MAVEN_IMAGE_TAG=3.8-eclipse-temurin-11
- MAVEN_OPTS="-Xmx512M"
- GEOSERVER_VERSION=2.19.7 (testado com 2.17.x, 2.19.x, 2.21.x, 2.22.x, 2.23.x)
- GEOSERVER_DATA_DIR=/srv/geoserver/data
- GEOSERVER_EXTENSIONS=oracle,sqlserver,excel,app-schema,importer,jms-cluster,backup-restore,control-flow

## Environment Variables
- GEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}
- GEOSERVER_VERSION=${GEOSERVER_VERSION}
- GEOSERVER_CONSOLE_DISABLED=FALSE
- GEOSERVER_CSRF_DISABLED=TRUE
- GEOSERVER_APPSCHEMA_PROPERTIES_FILE