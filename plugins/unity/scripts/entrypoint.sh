#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  rm -rvf "$DESTINATION/unity-$VERSION"
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh
fi
