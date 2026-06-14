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

# Base path for wetty (matches ingress nginx rewrite rule)
WETTY_BASE="/polaris/$WORKSTATION_NAME"
SESSION_NAME="juno-wetty-${WORKSTATION_NAME}"

# Start wetty as a WebSocket-to-terminal bridge.
# The wetty image CMD is: yarn run which expands to: NODE_ENV=production node .
# We run node . directly (same expansion) so the -c flag works correctly.
# The -c flag runs a command in the shell, bypassing the login form.
# (same pattern as the Hermes agent plugin at:
#  plugins/hermes-agent/scripts/chart/templates/init-script-configmap.yaml)
cd /usr/src/app
cmd = "tmux new-session -A -s $SESSION_NAME bash"
LANG=C.UTF-8 LC_ALL=C.UTF-8 COLORTERM=truecolor NODE_ENV=production node . -b "$WETTY_BASE" --allow-iframe -p 3000 -c "bash" &

# Wait forever (keeps the container alive)
exec tail -f /dev/null
