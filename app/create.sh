#!/bin/sh

cd /root/app

# terraform init 02-networking
# terraform apply -auto-approve -var "gce_zone=${GCLOUD_ZONE}" 02-networking

terraform init 03-provisioning
terraform apply -auto-approve \
    -var "gce_zone=${GCLOUD_ZONE}" \
    -var "gce_project=${GCLOUD_PROJECT}" \
    -var "gce_region=${GCLOUD_REGION}" \
    -var "gce_sa_email=${GCE_EMAIL}" \
    -var "gce_network=${GCLOUD_NETWORK}" \
    -var "gce_subnetwork=${GCLOUD_REGION}" \
    03-provisioning

00-ansible/create-inventory.sh 

ansible-playbook -i hosts_internal.ini 04-haproxy/haproxy-playbook.yml

ansible-playbook -i hosts_internal.ini 05-docker/docker-playbook.yml
