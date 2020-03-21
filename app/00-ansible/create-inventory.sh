#!/bin/sh

BASTION_EXTERNAL_IP=$(gcloud compute instances list --filter="(name:bastion)" | grep -v NAME | awk '{print $5}') 

cat > hosts_external.ini <<EOF
[all]
$(gcloud compute instances list --filter="(name:bastion*)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s ansible_user=ansible ansible_ssh_common_args=\x27-o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=30m -o ConnectionAttempts=100 -o UserKnownHostsFile=/dev/null\x27\n",$1,$5,$4;}')
$(gcloud compute instances list --filter="(name:master*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_user=ansible ansible_ssh_common_args=\x27-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=30m -o ConnectionAttempts=100 -o UserKnownHostsFile=/dev/null -W %%h:%%p -q ansible@" bastion_ip "\"\x27\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:worker*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_user=ansible ansible_ssh_common_args=\x27-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=30m -o ConnectionAttempts=100 -o UserKnownHostsFile=/dev/null -W %%h:%%p -q ansible@" bastion_ip "\"\x27\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:nfs*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_user=ansible ansible_ssh_common_args=\x27-o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=30m -o ConnectionAttempts=100 -o UserKnownHostsFile=/dev/null -W %%h:%%p -q ansible@" bastion_ip "\"\x27\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:haproxy*)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s ansible_user=ansible ansible_ssh_common_args=\x27-o StrictHostKeyChecking=no\x27\n",$1,$5,$4;}')

[kube-master]
$(gcloud compute instances list --filter="(name:master-*)" | grep -v NAME | awk '{ print $1 }')

[etcd]
$(gcloud compute instances list --filter="(name:master-*)" | grep -v NAME | awk '{ print $1 }')

[kube-node]
$(gcloud compute instances list --filter="(name:master-*)" | grep -v NAME | awk '{ print $1 }')
$(gcloud compute instances list --filter="(name:worker-*)" | grep -v NAME | awk '{ print $1 }')

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

cat > hosts_internal.ini <<EOF
[all]
$(gcloud compute instances list --filter="(name:bastion*)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s ansible_user=ansible ansible_ssh_common_args=\x27-o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPersist=30m -o ConnectionAttempts=100 -o UserKnownHostsFile=/dev/null\x27\n",$1,$5,$4;}')
$(gcloud compute instances list --filter="(name:master*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_user=ansible\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:worker*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_user=ansible\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:nfs*)" | grep -v NAME | awk -v bastion_ip="$BASTION_EXTERNAL_IP" '{printf "%s ansible_host=%s ip=%s ansible_user=ansible\n",$1,$4,$4;}')
$(gcloud compute instances list --filter="(name:haproxy*)" | grep -v NAME | awk '{printf "%s ansible_host=%s ip=%s ansible_user=ansible\n",$1,$5,$4;}')

[kube-master]
$(gcloud compute instances list --filter="(name:master-*)" | grep -v NAME | awk '{ print $1 }')

[etcd]
$(gcloud compute instances list --filter="(name:master-*)" | grep -v NAME | awk '{ print $1 }')

[kube-node]
$(gcloud compute instances list --filter="(name:master-*)" | grep -v NAME | awk '{ print $1 }')
$(gcloud compute instances list --filter="(name:worker-*)" | grep -v NAME | awk '{ print $1 }')

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
