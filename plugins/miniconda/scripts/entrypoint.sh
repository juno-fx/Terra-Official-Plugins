#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  echo "Cleaning up environment $ENVIRONMENT_NAME"
  rm -rf "$DESTINATION/envs/$ENVIRONMENT_NAME"
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh
fi
