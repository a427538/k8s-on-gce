#!/bin/sh

export ETCD_VERSION=v3.3.5
export CNI_VERSION=0.3.1
export CNI_PLUGINS_VERSION=v0.6.0
export CONTAINERD_VERSION=1.2.0-rc.0

rm -f /root/.ssh/google_compute_engine*
# ⚠️ Here we create a key with no passphrase
ssh-keygen -q -P "" -f /root/.ssh/google_compute_engine

terraform init 03-provisioning

terraform apply -auto-approve -var "gce_zone=${GCLOUD_ZONE}" 03-provisioning
