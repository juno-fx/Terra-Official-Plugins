#!/bin/bash
set -e

if [[ -z "${PREFIX:-}" ]]; then
    echo "ERROR: PREFIX environment variable must be set and not empty"
    exit 1
fi

echo "Longhorn dashboard configured at PREFIX: $PREFIX"
