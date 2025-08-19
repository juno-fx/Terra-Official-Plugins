#!/bin/bash
set -e

if [ -z "${PREFIX:-}" ]; then
    echo "Error: PREFIX environment variable is required but not set"
    exit 1
fi

if [ "${CLEANUP:-}" = "true" ]; then
    echo "Running cleanup with PREFIX: $PREFIX"
    ./cleanup.sh
else
    echo "Starting ArgoCD configuration with PREFIX: $PREFIX"
    ./configure.sh
fi
