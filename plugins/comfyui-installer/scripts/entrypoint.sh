#!/bin/bash

set -e
echo "Starting entrypoint script..."

# check that the DESTINATION environment variable is set
if [ -z "$DESTINATION" ]; then
  echo "DESTINATION environment variable is not set. Exiting."
  exit 1
fi

# check if the INSTALL environment variable is set then update the system
if [ -n "${INSTALL}" ]; then
    ./installer.sh "$DESTINATION"
fi

# check if the CLEANUP environment variable is set
if [ -n "$CLEANUP" ]; then
  # remove the Destination directory
  echo "Cleaning up the destination directory..."
  rm -rf "$DESTINATION/comfyui"
  echo "Cleanup completed."
fi