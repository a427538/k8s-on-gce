#!/bin/bash

docker run -it \
        -v $PWD/app:/root/app \
        -v $PWD/kubespray/inventory/mycluster:/root/kubespray/inventory/mycluster \
        -p 8001:8001 \
        --name k8s-on-gce-tools netactiv/k8s-on-gce-tools:latest
