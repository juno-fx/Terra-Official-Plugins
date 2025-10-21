set -e

apt update
apt upgrade -y

apt install -y \
  curl \
  tar

# setup workspace
mkdir -pv ${DESTINATION}
cd ${DESTINATION}

# download the runner package
echo "curl -o runner.tar.gz -L https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"
curl -o runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"

# extract the runner package
tar -xzf runner.tar.gz

# configure the runner
./config.sh --unattended \
  --url "${REPO_URL}" \
  --token "${TOKEN}" \
  --name "${NAME}"
