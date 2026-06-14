#!/bin/sh
set -e

cd /usr/src/app

# delete default node user to avoid uid issues for users/groups with uids of 1000
deluser --remove-home node || echo "user node doesn't exist"

addgroup -g "$PGID" wettyusers || echo "group already exists"

adduser -D -u "$PUID" -G wettyusers "$USER" || echo "user already exists"

# Set correct home directory ownership
mkdir -p /home/$USER
chown -R $PUID:$PGID /home/$USER

if [ -n "$PACKAGES" ]; then
  # shellcheck disable=SC2086
  apk add $PACKAGES
fi

# Install tmux for session persistence (Alpine uses apk)
if ! command -v tmux &>/dev/null; then
  apk add --no-cache tmux >/dev/null 2>&1
fi

# The entrypoint is `node ./build/main.js` — wetty is a Node.js app, not a binary

# Base path for wetty (matches ingress nginx rewrite rule)
WETTY_BASE="/polaris/$WORKSTATION_NAME"
SESSION_NAME="juno-wetty-${WORKSTATION_NAME}"

# Start wetty as a WebSocket-to-terminal bridge via the Node.js entrypoint.
# The -c flag runs a command in the shell, bypassing the login form.
# (same pattern as the Hermes agent plugin at:
#  plugins/hermes-agent/scripts/chart/templates/init-script-configmap.yaml)
node ./build/main.js -b "$WETTY_BASE" --allow-iframe -p 3000 \
  -c "tmux new-session -A -s $SESSION_NAME bash" &

# Wait forever (keeps the container alive)
exec tail -f /dev/null
