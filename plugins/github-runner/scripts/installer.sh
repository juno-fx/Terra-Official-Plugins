set -e

apt update
apt install -y \
  curl \
  tar

# setup workspace
mkdir -pv /host/${DESTINATION}/${NAME}
cd /host/${DESTINATION}/${NAME}

# download the runner package
echo "curl -o runner.tar.gz -L https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"
curl -o runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"

# extract the runner package
tar -xzf runner.tar.gz

# install provision script
cp /terra/run.sh ./provision.sh
chmod +x ./provision.sh

# chroot and run provision script
chroot /host/ bash -c "cd /${DESTINATION}/${NAME} && RUNNER_ALLOW_RUNASROOT='1' REPO_URL=${REPO_URL} TOKEN=${TOKEN} NAME=${NAME} ./provision.sh"
