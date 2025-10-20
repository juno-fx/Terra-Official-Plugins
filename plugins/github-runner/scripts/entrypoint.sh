#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  rm -rvf "$DESTINATION/$NAME"
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh
fi
