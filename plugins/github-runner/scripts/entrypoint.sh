#!/bin/bash
set -e

# install required tools
apt update
apt install -y \
  curl \
  tar \
  rsync

# clean up any previous installation
mkdir -pv /${DESTINATION}/${NAME}
mkdir -pv /host/opt/github/runners/${NAME}

# fresh runner install
if [ -n "${INSTALL}" ]; then
    # change to workspace
    cd /host/opt/github/runners/${NAME}

    # download the runner package
    echo "curl -o runner.tar.gz -L https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"
    curl -o runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"

    # extract the runner package
    tar -xzf runner.tar.gz
    rm -rfv runner.tar.gz

    # chroot and run provision script
    chroot /host/ bash -c "cd /opt/github/runners/${NAME} && RUNNER_ALLOW_RUNASROOT='1' ./config.sh --unattended --url ${URL} --token ${TOKEN} --name ${NAME} --replace"

    echo "Copying runner configuration to shared storage..."
    mkdir -pv /${DESTINATION}/${NAME}
    rsync -a -P /host/opt/github/runners/${NAME}/ /${DESTINATION}/${NAME}/
    rsync -a -P /host/opt/github/runners/${NAME}/.* /${DESTINATION}/${NAME}/
    echo "GitHub Actions Runner v${VERSION} installed at ${DESTINATION}/${NAME}"

    exit 0
fi

if [ -n "${LAUNCH}" ]; then
    # pull the runners configuration from shared storage
    echo "Restoring runner configuration from shared storage..."
    rsync -a /${DESTINATION}/${NAME}/ /host/opt/github/runners/${NAME}/
    echo "Configuration restored."
    ls -la /host/opt/github/runners/${NAME}/
    ls -la /${DESTINATION}/${NAME}/

    # chroot and run the run.sh script
    echo "Launching GitHub Actions Runner..."
    chroot /host/ bash -c "cd /opt/github/runners/${NAME}/ && RUNNER_ALLOW_RUNASROOT='1' ./svc.sh install root" || echo "Service seems to already be installed...continuing."
    chroot /host/ bash -c "cd /opt/github/runners/${NAME}/ && RUNNER_ALLOW_RUNASROOT='1' ./svc.sh start"
    echo "GitHub Actions Runner launched."
    sleep infinity
    exit 0
fi
