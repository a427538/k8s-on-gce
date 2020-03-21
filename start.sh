#!/bin/bash

source $PWD/profile

docker run -it \
        -v $PWD/app:/root/app \
        -v $PWD/kubespray/inventory/mycluster:/root/kubespray/inventory/mycluster \
        -p 8001:8001 \
        --name kubespray-infra eu.gcr.io/${GCLOUD_PROJECT}/kubespray-infra:latest
