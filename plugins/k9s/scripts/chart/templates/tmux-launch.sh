#!/bin/sh
# tmux-launch.sh — entry point for wetty sessions under a specific user
# Called via: gosu <user> /opt/boot/tmux-launch.sh
# Sources tmux-boot.sh for the exec_tmux function, then launches the
# target application in a persistent tmux session.

set -e

source /opt/boot/tmux-boot.sh

# --- k9s ---
exec_tmux 'k9s; exec /bin/bash -l'
