#!/bin/sh

source $PWD/profile

docker build . -t eu.gcr.io/${GCLOUD_PROJECT}/kubespray-infra

if [ $? -eq 0 ]; then
    docker rm -f kubespray-infra
    docker push eu.gcr.io/${GCLOUD_PROJECT}/kubespray-infra:latest
fi
