#!/bin/bash
# Startup probe for BOINC — attaches project and checks readiness
# Runs via kubelet exec, inherits container env vars (PROJECT_URL, ACCOUNT_KEY)
P=$(cat /config/gui_rpc_auth.cfg 2>/dev/null || echo "")
if [ -n "$P" ] && [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  boinccmd --passwd "$P" --project_attach "$PROJECT_URL" "$ACCOUNT_KEY" 2>/dev/null
fi
P=$(cat /config/gui_rpc_auth.cfg 2>/dev/null || echo "")
[ -n "$P" ] && boinccmd --passwd "$P" --get_state 2>/dev/null | grep -q "master URL"
