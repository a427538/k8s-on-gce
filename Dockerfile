FROM python:3.8-alpine

ENV TERRAFORM_VERSION=0.12.29 \
    GCLOUD_SDK_VERSION=301.0.0 \
    CFSSL_VERSION=R1.2 \
    KUBE_VERSION=v1.17.8 \
    KUBESPRAY_RELEASE=release-2.13 \
    ROOK_RELEASE=release-1.3

ENV GCLOUD_SDK_FILE=google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    TERRAFORM_FILE=terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# RUN apk update && \
RUN apk add bash curl git openssh-client gcc make musl-dev libffi-dev openssl openssl-dev jq && \
    curl -o /root/$GCLOUD_SDK_FILE https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$GCLOUD_SDK_FILE && \
    curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/$CFSSL_VERSION/cfssl_linux-amd64 && \
    curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/$CFSSL_VERSION/cfssljson_linux-amd64 && \
    curl -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl && \
    curl -o /root/$TERRAFORM_FILE https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/$TERRAFORM_FILE

WORKDIR /root

RUN unzip $TERRAFORM_FILE && \
    mv terraform /usr/local/bin && \
    rm $TERRAFORM_FILE && \
    tar xzf $GCLOUD_SDK_FILE && \
    /root/google-cloud-sdk/install.sh -q && \
    /root/google-cloud-sdk/bin/gcloud config set disable_usage_reporting true && \
    rm /root/${GCLOUD_SDK_FILE} && \
    chmod +x /usr/local/bin/cfssl* /usr/local/bin/kubectl && \
    git clone https://github.com/kubernetes-sigs/kubespray.git && \
    cd kubespray && \
    git checkout ${KUBESPRAY_RELEASE} && \
    git clone https://github.com/rook/rook.git && \
    cd rook && \
    git checkout ${ROOK_RELEASE} && \
    mkdir -p inventory/mycluster && \
    pip install -r requirements.txt && \
    pip install requests google-auth apache-libcloud openshift && \
    cd ..

RUN ansible-galaxy install geerlingguy.docker
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

ADD profile /root/.bashrc
ADD ssh_keys /root/.ssh
ADD ansible.cfg /root/.ansible.cfg
ADD ansible.cfg /root/kubespray/ansible.cfg

WORKDIR /root/app

ENTRYPOINT [ "/bin/bash" ]

