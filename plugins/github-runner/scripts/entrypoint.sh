#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  rm -rvf "$DESTINATION/$NAME"
  exit 0
fi

# install required tools
apt update
apt install -y \
  curl \
  tar \
  rsync

# clean up any previous installation
rm -rf /host/${DESTINATION}/${NAME}
mkdir -pv /host/${DESTINATION}/${NAME}

# fresh runner install
if [ -n "${INSTALL}" ]; then
    # clean previous network install
    rm -rf /${DESTINATION}/${NAME}

    # change to workspace
    cd /host/${DESTINATION}/${NAME}

    # download the runner package
    echo "curl -o runner.tar.gz -L https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"
    curl -o runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"

    # extract the runner package
    tar -xzf runner.tar.gz

    # chroot and run provision script
    chroot /host/ bash -c "cd /${DESTINATION}/${NAME} && RUNNER_ALLOW_RUNASROOT='1' ./config.sh --unattended --url ${URL} --token ${TOKEN} --name ${NAME} --replace"

    echo "Copying runner configuration to shared storage..."
    rsync -a /host/${DESTINATION}/${NAME}/ /${DESTINATION}/${NAME}/
    echo "GitHub Actions Runner v${VERSION} installed at ${DESTINATION}/${NAME}"

    exit 0
fi

if [ -n "${LAUNCH}" ]; then
    # pull the runners configuration from shared storage
    echo "Restoring runner configuration from shared storage..."
    rsync -a /${DESTINATION}/${NAME}/ /host/${DESTINATION}/${NAME}/
    echo "Configuration restored."

    # chroot and run the run.sh script
    echo "Launching GitHub Actions Runner..."
    chroot /host/ bash -c "cd /${DESTINATION}/${NAME} && ./run.sh"

    exit 0
fi
