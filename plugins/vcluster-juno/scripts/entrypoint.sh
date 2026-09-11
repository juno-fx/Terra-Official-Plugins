#!/bin/bash
set -e

if [ "${CLEANUP:-}" = "true" ]; then
    echo "Running vcluster-juno cleanup..."
    ./cleanup.sh
else
    echo "Running vcluster-juno install..."
    ./install.sh
fi
