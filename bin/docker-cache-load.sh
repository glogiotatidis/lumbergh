#!/bin/bash
for CACHE in `ls ${1}`;
do
    gunzip -c ${1}/${CACHE} | docker load
done
