#!/bin/sh

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-easy-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(name)')
#terraform destroy -var "gce_ip_address=${KUBERNETES_PUBLIC_ADDRESS}" 08-kube-master

gcloud -q compute forwarding-rules delete --region europe-west1 kubernetes-forwarding-rule
gcloud -q compute target-pools delete kubernetes-target-pool

terraform destroy -var "gce_zone=${GCLOUD_ZONE}" -force 03-provisioning/
