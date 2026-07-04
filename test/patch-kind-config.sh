#!/usr/bin/env bash
# Injects ~/.docker/config.json as an extraMount into Kind config.
# This lets containerd use authenticated pulls, avoiding Docker Hub rate limits.
set -euo pipefail

config="$1"
patched="${config}.patched"
dc="$HOME/.docker/config.json"

cp "$config" "$patched"

if [[ ! -f "$dc" ]]; then
    echo "  [SKIP] No Docker config found at $dc — skipping credential mount"
    exit 0
fi

# Only inject if extraMounts section exists and mount isn't already present
if grep -q 'extraMounts:' "$patched" && ! grep -q 'containerPath: /var/lib/kubelet/config.json' "$patched"; then
    # Detect indent from the first mount entry
    indent="$(awk '/extraMounts:/ { f=1; next } f && /- hostPath:/ { match($0,/^[ \t]*/); print substr($0,RSTART,RLENGTH); exit }' "$patched")"
    [[ -z "$indent" ]] && indent="      "

    awk -v dc="$dc" -v ind="$indent" '
    /^[[:space:]]*extraMounts:/ {
        print
        print ind "- hostPath: \"" dc "\""
        print ind "  containerPath: /var/lib/kubelet/config.json"
        next
    }
    { print }
    ' "$patched" > "$patched.tmp" && mv "$patched.tmp" "$patched"

    echo "  [OK]   Mounted Docker config into Kind node"
else
    echo "  [SKIP] No extraMounts section or mount already present"
fi
