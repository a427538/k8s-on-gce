#!/bin/sh

source $PWD/profile

docker build --network host . -t netactiv/k8s-on-gce-tools:latest

if [ $? -eq 0 ]; then
    docker rm -f kubespray-infra
    docker push netactiv/k8s-on-gce-tools:latest
fi
