#!/bin/bash

set -e

echo "Starting KubeVirt ISO Importer entrypoint script..."

apt update
apt install -y wget curl

export VERSION=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64

mv virtctl-${VERSION}-linux-amd64 /usr/local/bin/virtctl
chmod +x /usr/local/bin/virtctl

echo "System ready. Starting download..."

cd /tmp/

#wget

virtctl image-upload dv windows-dv \
  --uploadproxy-url="https://${CDI_PROXY}" \
  --image-path=/home/aldmbmtl/Downloads/Win11_25H2_English_x64.iso \
  --size 10Gi --access-mode ReadWriteOnce --insecure --force-bind


#virtctl image-upload dv windows-dv \
#  --uploadproxy-url=https://localhost:8443 \
#  --image-path=/home/aldmbmtl/Downloads/Win11_25H2_English_x64.iso \
#  --size 10Gi --access-mode ReadWriteOnce --insecure --force-bind