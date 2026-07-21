#!/usr/bin/with-contenv bash
set -e

# s6-overlay init script — runs before boinc-client starts
# Rewrites svc-boinc-client/run to auto-attach project on startup
# Rewrites labwc autostart to wait for project before launching boincmgr

# Write cc_config with CPU limit from cgroup
if [ -f /sys/fs/cgroup/cpu.max ]; then
  NCPUS=$(awk '{print int($1/100000)}' /sys/fs/cgroup/cpu.max 2>/dev/null || nproc)
else
  NCPUS=$(nproc)
fi
echo "<cc_config>
  <options>
    <ncpus>$NCPUS</ncpus>
  </options>
</cc_config>" > /config/cc_config.xml

# Write RAM limit to global_prefs_override.xml (80% of available)
cat > /config/global_prefs_override.xml <<'PREFS'
<global_preferences>
  <ram_max_used_busy_pct>80</ram_max_used_busy_pct>
  <ram_max_used_idle_pct>80</ram_max_used_idle_pct>
</global_preferences>
PREFS
chown abc:abc /config/global_prefs_override.xml

# Rewrite boinc service to attach project after startup
if [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  cat > /etc/s6-overlay/s6-rc.d/svc-boinc-client/run <<'SERVICEFILE'
#!/usr/bin/with-contenv bash
s6-setuidgid abc /usr/bin/boinc --dir /config &
# Retry project_attach for up to 60s (12 attempts x 5s apart)
for i in $(seq 1 12); do
  sleep 5
  GUI_PASS=$(cat /config/gui_rpc_auth.cfg 2>/dev/null || echo "")
  if [ -n "$GUI_PASS" ] && [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
    boinccmd --passwd "$GUI_PASS" --project_attach "$PROJECT_URL" "$ACCOUNT_KEY" 2>/dev/null
  fi
done
boinccmd --passwd "$GUI_PASS" --read_global_prefs_override 2>/dev/null || true
wait
SERVICEFILE
  chmod 755 /etc/s6-overlay/s6-rc.d/svc-boinc-client/run
fi

# Rewrite labwc autostart to wait for project before launching boincmgr
mkdir -p /config/.config/labwc
cat > /config/.config/labwc/autostart <<'AUTOSTART'
#!/bin/bash
while ! grep -q '<project>' /config/client_state.xml 2>/dev/null; do
  sleep 1
done
/usr/bin/boincmgr
AUTOSTART
chmod 755 /config/.config/labwc/autostart
