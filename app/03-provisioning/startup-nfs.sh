#!/bin/bash -xe

cat << 'EOF' >> /etc/environment
export http_proxy=http://bastion.k8s.totopos.de:3128
export https_proxy=http://bastion.k8s.totopos.de:3128
export ftp_proxy=http://bastion.k8s.totopos.de:3128
export no_proxy=127.0.0.1,localhost
EOF

apt-get update
apt-get install python -y