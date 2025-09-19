#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  rm -rvf "$DESTINATION"
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh "$URL" "$DESTINATION"
fi
