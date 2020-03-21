#!/bin/bash

cat << 'EOF' >> /etc/environment
export http_proxy=http://bastion.k8s.totopos.de:3128
export https_proxy=http://bastion.k8s.totopos.de:3128
export ftp_proxy=http://bastion.k8s.totopos.de:3128
export no_proxy=127.0.0.1,localhost
EOF

yum check-update
yum install -y yum-utils device-mapper-persistent-data lvm2

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

yum install -y google-cloud-sdk python docker-ce-18.06.3.ce-3.el7 containerd.io git

systemctl start docker

systemctl enable docker


cat << 'EOF' > /home/ansible/.ssh/id_rsa
-----BEGIN OPENSSH PRIVATE KEY-----
<privatekey>
-----END OPENSSH PRIVATE KEY-----
EOF

cat << 'EOF' > /home/ansible/.ssh/id_rsa.pub
<publickey>
EOF

chown -R ansible: /home/ansible/.ssh/id_rsa*
chmod 0600 /home/ansible/.ssh/id_rsa

usermod -aG docker ansible

gcloud -q auth configure-docker && docker login gcr.io

