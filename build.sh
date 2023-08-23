#!/bin/bash

for GEOSERVER_VERSION in "2.17.5" "2.18.7" "2.19.7" "2.20.7" "2.21.5" "2.22.4" "2.23.2"
do 
    docker build --pull --rm -f "Dockerfile" --build-arg "GEOSERVER_VERSION=${GEOSERVER_VERSION}" \
        -t ndscprm/geoserver:${GEOSERVER_VERSION} "."

    docker push ndscprm/geoserver:${GEOSERVER_VERSION}

    echo "Scanning..."
    docker scan ndscprm/geoserver:${GEOSERVER_VERSION} > scans/geoserver-${GEOSERVER_VERSION}-scan.txt
done
