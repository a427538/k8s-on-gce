#!/bin/sh

docker build . -t netactiv/k8s-on-gce-tools

if [ $? -eq 0 ]; then
    docker rm -f k8s-on-gce-tools 
    
    docker tag netactiv/k8s-on-gce-tools netactiv/k8s-on-gce-tools:latest
    docker push netactiv/k8s-on-gce-tools:latest
    
    docker run -it \
        -v $PWD/app:/root/app \
        -p 8001:8001 \
        --name k8s-on-gce-tools netactiv/k8s-on-gce-tools:latest
fi
