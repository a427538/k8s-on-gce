#!/bin/sh

BASTION_EXTERNAL_IP=$(gcloud compute instances list --filter="(name:bastion-0)" | grep -v NAME | awk '{print $5}') 

cat > hosts.ini <<EOF
[all]
$(gcloud compute instances list --filter="(name:bastion-0)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s\n",$1,$5,$4;}')
$(gcloud compute instances list --filter="(name:node-*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_ssh_common_args=\x27-o ProxyCommand=\"ssh -i ~/.ssh/google_compute_engine -W %%h:%%p -q " bastion_ip "\"\x27\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:nfs-*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_ssh_common_args=\x27-o ProxyCommand=\"ssh -i ~/.ssh/google_compute_engine -W %%h:%%p -q " bastion_ip "\"\x27\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:haproxy-*)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s\n",$1,$5,$4;}')

[kube-master]
$(gcloud compute instances list --filter="(tags.items:kube-master)" | grep -v NAME | awk '{ print $1 }')

[etcd]
$(gcloud compute instances list --filter="(tags.items:etcd)" | grep -v NAME | awk '{ print $1 }')

[kube-node]
$(gcloud compute instances list --filter="(tags.items:kube-node)" | grep -v NAME | awk '{ print $1 }')

[calico-rr]

[k8s-cluster:children]
kube-master
kube-node
calico-rr

[haproxy]
$(gcloud compute instances list --filter="(tags.items:haproxy)" | grep -v NAME | awk '{ print $1 }')

[nfs]
$(gcloud compute instances list --filter="(tags.items:nfs)" | grep -v NAME | awk '{ print $1 }')

EOF
