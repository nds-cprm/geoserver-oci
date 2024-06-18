# https://docs.geoserver.org/2.19.x/en/developer/index.html
# https://docs.geoserver.org/2.19.x/en/developer/maven-guide/index.html

# https://geoserver.org/download/
# Java 8 -> 2.9 a 2.22
# Java 11 -> 2.15 a 2.23
# Java 17 -> >2.23
ARG MAVEN_IMAGE_TAG=3.8-eclipse-temurin-11
ARG TOMCAT_IMAGE_TAG=9-jre11-temurin-jammy
ARG GEOSERVER_VERSION=2.24.2

FROM docker.io/library/maven:${MAVEN_IMAGE_TAG} AS BUILDER

ARG GEOSERVER_VERSION
ARG GEOSERVER_GIT_URL=https://github.com/geoserver/geoserver.git
ARG MAVEN_OPTS="-Xmx512M"
ARG GEOSERVER_EXTENSIONS=oracle,sqlserver,excel,app-schema,importer,jms-cluster,backup-restore,control-flow

ENV MAVEN_OPTS ${MAVEN_OPTS}

WORKDIR /root

RUN git clone ${GEOSERVER_GIT_URL} geoserver

WORKDIR /root/geoserver

RUN set -xe && \
    git checkout tags/${GEOSERVER_VERSION} -b docker-builder

VOLUME ["/root/.m2"]

WORKDIR /root/geoserver/src

RUN mvn -DskipTests clean install \
        -P $GEOSERVER_EXTENSIONS | tee install.log && \
    mv install.log ./web/app/target/geoserver/install.log


FROM docker.io/library/tomcat:${TOMCAT_IMAGE_TAG} AS RELEASE

ARG GEOSERVER_VERSION
ARG GEOSERVER_DATA_DIR=/srv/geoserver/data
ARG GEOSERVER_UID=10000
ARG GEOSERVER_GID=10000

LABEL org.opencontainers.image.title "GeoServer SGB/CPRM"
LABEL org.opencontainers.image.description "Build de geoserver a partir do código fonte"
LABEL org.opencontainers.image.vendor "SGB/CPRM"
LABEL org.opencontainers.image.version "${GEOSERVER_VERSION}"
LABEL org.opencontainers.image.source "https://github.com/nds-cprm/geoserver-oci"
LABEL org.opencontainers.image.authors "Carlos Eduardo Mota <carlos.mota@sgb.gov.br>"

# base libs
RUN apt-get -y update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        gettext-base && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

# Copy built
COPY --from=BUILDER /root/geoserver/src/web/app/target/geoserver/ ./webapps/geoserver/

ENV GEOSERVER_VERSION=${GEOSERVER_VERSION} \
    GEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}

# Entrypoint
COPY docker-entrypoint.sh /

# web.xml CORS enabled
COPY assets/web.xml ./webapps/geoserver/WEB-INF/

# Geoserver default data dir
RUN groupadd -g ${GEOSERVER_GID} geoserver && \
    useradd -m -d /var/lib/geoserver -s /sbin/nologin -c "Geoserver" \
        -u ${GEOSERVER_UID} -g ${GEOSERVER_GID} -N geoserver && \
    mkdir -p ${GEOSERVER_DATA_DIR} && \
    chgrp -R geoserver ./webapps/geoserver/data ${GEOSERVER_DATA_DIR} && \
    chmod -R g=u ./webapps/geoserver/data ${GEOSERVER_DATA_DIR} && \
    chmod +x /docker-entrypoint.sh

# CORS
# https://tomcat.apache.org/tomcat-9.0-doc/config/filter.html#CORS_Filter
# https://docs.geoserver.org/main/en/user/production/container.html#enable-cors-for-tomcat
ENV GEOSERVER_CORS_ALLOWED_ORIGINS=""

COPY assets/web.xml.envsubst ./webapps/geoserver/WEB-INF/

RUN touch ./webapps/geoserver/WEB-INF/web.xml && \
    chown geoserver:geoserver ./webapps/geoserver/WEB-INF/web.xml

VOLUME [ "${GEOSERVER_DATA_DIR}" ]

USER geoserver

WORKDIR /var/lib/geoserver

RUN mkdir .fonts backups

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["catalina.sh", "run"]
