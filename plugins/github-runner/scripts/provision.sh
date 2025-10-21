# echo all configurations

set -e

echo "./config.sh --unattended --url ${URL} --token ${TOKEN} --name ${NAME}"

# configure the runner
./config.sh remove || true
./config.sh --unattended --url ${URL} --token ${TOKEN} --name ${NAME} --replace
