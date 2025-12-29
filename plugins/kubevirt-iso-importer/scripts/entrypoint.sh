#!/bin/bash

set -e

echo "Starting KubeVirt ISO Importer entrypoint script..."

apt update
apt install -y wget curl

export VERSION=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64

mv virtctl-${VERSION}-linux-amd64 /usr/local/bin/virtctl
chmod +x /usr/local/bin/virtctl

cd /tmp/
mkdir -pv cache
cd cache

echo "System ready. Starting download..."

# download the ISO file from the provided URL
wget --progress=dot:giga "${URL}"

FILENAME=$(basename "${URL}")
echo "Downloaded file: ${FILENAME}"
ls -la

echo "Starting upload to DataVolume..."

# upload the ISO file to the specified DataVolume
virtctl image-upload dv "${DV_NAME}" \
  --uploadproxy-url="https://${CDI_PROXY}" \
  --image-path="/tmp/cache/${FILENAME}" \
  --size "${SIZE}" --access-mode ReadWriteOnce --insecure --force-bind
echo "Upload completed."
echo "Cleaning up..."
rm -rf /tmp/cache/*
echo "Done."