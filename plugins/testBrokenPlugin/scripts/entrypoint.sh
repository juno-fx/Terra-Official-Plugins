#!/bin/bash
set -e

if [ -n "$CLEANUP" ]; then
  rm -rvf "$DESTINATION"
  exit 0
else
  apt update
  apt install -y git

  # Run the command
  git clone "$REPO" "$DESTINATION"
  cd "$DESTINATION"
  git checkout "$REF"
fi
