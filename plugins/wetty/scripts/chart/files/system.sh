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

# Install tmux for session persistence (Alpine uses apk)
if ! command -v tmux &>/dev/null; then
  apk add --no-cache tmux >/dev/null 2>&1
fi

# Start wetty inside tmux session for persistence
# When wetty exits, re-exec this script to restart it in a fresh session
SESSION_NAME="juno-wetty-${WORKSTATION_NAME}"

tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
tmux new-session -d -s "$SESSION_NAME" "yarn start --base \"/polaris/$WORKSTATION_NAME\" --allow-iframe; exec $0"

# Wait forever (keeps the container alive)
exec tail -f /dev/null
