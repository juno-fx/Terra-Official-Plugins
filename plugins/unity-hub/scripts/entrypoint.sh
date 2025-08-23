#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  apt-get remove unityhub
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh
fi
