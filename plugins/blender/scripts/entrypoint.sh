#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  rm -rvf "$DESTINATION/blender-$VERSION-linux-x64"
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh "$VERSION" "$DESTINATION"
fi
