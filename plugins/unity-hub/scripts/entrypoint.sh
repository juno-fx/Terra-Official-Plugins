#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  sudo apt-get remove unityhub
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh
fi
