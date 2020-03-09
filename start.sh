#!/bin/bash

docker run -it \
        -v $PWD/app:/root/app \
        -p 8001:8001 \
        --name k8s-on-gce-tools k8s-on-gce/tools
