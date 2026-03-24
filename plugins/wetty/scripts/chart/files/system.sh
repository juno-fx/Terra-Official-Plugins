#!/bin/sh
set -e

cd /usr/src/app

# delete default node user to avoid uid issues for users/groups with uids of 1000
deluser --remove-home node || echo "user node doesn't exist"

addgroup -g "$PGID" wettyusers || echo "group already exists"

adduser -D -u "$PUID" -G wettyusers "$USER" || echo "user already exists"

echo "$USER:$USER_PASS" | chpasswd

if [ -n "$PACKAGES" ]; then
  # shellcheck disable=SC2086
  apk add $PACKAGES
fi

yarn start --base "/polaris/$WORKSTATION_NAME" --allow-iframe
