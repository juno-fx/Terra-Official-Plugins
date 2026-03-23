#!/bin/sh
set -e

cd /usr/src/app

addgroup -g "$PGID" wettyusers || echo "group already exists"

adduser -D -u "$PUID" -G wettyusers "$USER"

echo "$USER:$USER_PASS" | chpasswd

if [ -n "$PACKAGES" ]; then
  # shellcheck disable=SC2086
  apk add $PACKAGES
fi

yarn start --base "/polaris/$WORKSTATION_NAME" --allow-iframe
