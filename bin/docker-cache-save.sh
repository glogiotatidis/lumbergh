#!/bin/bash

LAYERS=`docker history -q ${DOCKER_REPOSITORY}:${TRAVIS_COMMIT} | tail -n +2 | grep -v '<missing>'`

for LAYER in $LAYERS;
do
    docker save ${LAYER} | gzip > ${1}/${LAYER}.tar.gz
done
