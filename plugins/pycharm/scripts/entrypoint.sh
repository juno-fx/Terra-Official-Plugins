#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  rm -rvf "$DESTINATION/pycharm-$VERSION"
  rm -rvf "$DESTINATION/pycharm-$VERSION/pycharm.desktop"
  exit 0
fi

if [ -n "${INSTALL}" ]; then
    ./installer.sh "$VERSION" "$DESTINATION"
fi
