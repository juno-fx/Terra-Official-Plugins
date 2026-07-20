#!/usr/bin/with-contenv bash
set -e

# s6-overlay init script — runs before boinc-client starts
# Rewrites svc-boinc-client/run to auto-attach project on startup

# Write cc_config with CPU limit from cgroup
if [ -f /sys/fs/cgroup/cpu.max ]; then
  NCPUS=$(awk '{int($1/100000)}' /sys/fs/cgroup/cpu.max 2>/dev/null || nproc)
else
  NCPUS=$(nproc)
fi
echo "<cc_config>
  <options>
    <ncpus>$NCPUS</ncpus>
  </options>
</cc_config>" > /config/cc_config.xml

# Rewrite boinc service to attach project after startup
if [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  cat > /etc/s6-overlay/s6-rc.d/svc-boinc-client/run <<'SERVICEFILE'
#!/usr/bin/with-contenv bash
s6-setuidgid abc /usr/bin/boinc --dir /config &
for i in $(seq 1 30); do
  if boinccmd --get_state > /dev/null 2>&1 && [ -f /config/gui_rpc_auth.cfg ]; then
    break
  fi
  sleep 0.5
done
GUI_PASS=$(cat /config/gui_rpc_auth.cfg 2>/dev/null || echo "")
if [ -n "$GUI_PASS" ] && [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  boinccmd --passwd "$GUI_PASS" --set_global_prefs "<global_preferences><ram_max_used_busy_pct>80</ram_max_used_busy_pct><ram_max_used_idle_pct>80</ram_max_used_idle_pct></global_preferences>" 2>/dev/null || true
  boinccmd --passwd "$GUI_PASS" --project_attach "$PROJECT_URL" "$ACCOUNT_KEY" 2>/dev/null || true
fi
wait
SERVICEFILE
  chmod 755 /etc/s6-overlay/s6-rc.d/svc-boinc-client/run
fi
