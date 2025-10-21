# echo all configurations

set -e

echo "RUNNER_ALLOW_RUNASROOT='1' ./config.sh --unattended --url '${URL}' --token '${TOKEN}' --name '${NAME}'"

# configure the runner
./config.sh --unattended --url "${URL}" --token "${TOKEN}" --name "${NAME}"
