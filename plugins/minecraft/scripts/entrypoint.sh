#!/bin/bash
set -e

if [ -n "${DOWNLOAD}" ]; then
    ./downloader.sh "$URL" "$DESTINATION"
fi

if [ -n "${CLEANUP}" ]; then
    ./cleanup.sh
fi
