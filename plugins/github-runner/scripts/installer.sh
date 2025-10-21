set -e

apt update
apt install -y \
  curl \
  tar

su ubuntu

# setup workspace
mkdir -pv ${DESTINATION}
cd ${DESTINATION}

# download the runner package
echo "curl -o runner.tar.gz -L https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"
curl -o runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz"

# extract the runner package
tar -xzf runner.tar.gz

su ubuntu
# configure the runner
su ubuntu -c "./config.sh --unattended --url \"${REPO_URL}\" --token \"${TOKEN}\" --name \"${NAME}\""
