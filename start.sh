#!/bin/bash

# source $PWD/profile

docker run -it \
        -v $PWD/app:/root/app \
        -v $PWD/kubespray/inventory/mycluster:/root/kubespray/inventory/mycluster \
        --network host \
        --name kubespray-infra netactiv/k8s-on-gce-tools:latest
