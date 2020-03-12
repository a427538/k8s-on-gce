#!/bin/sh

cat > hosts.ini <<EOF
[all]
$(gcloud compute instances list | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s\n",$1,$5,$4;}')
$(gcloud compute instances list --filter="(name:bastion-1)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s ansible_user=kstich\n",$1,$5,$4;}')
$(gcloud compute instances list --filter="(name:nfs-1)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s\n",$1,$5,$4;}')
$(gcloud compute instances list --filter="(name:haproxy-1)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s\n",$1,$5,$4;}')

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
