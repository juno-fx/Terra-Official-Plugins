#!/bin/bash
set -e

# s6-overlay init script — runs before boinc-client starts
# Schedules project attach via nohup to survive s6 init transition

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

# Schedule attach — nohup survives s6 init-to-service transition
if [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  nohup /bin/bash -c '
    sleep 15
    GUI_PASS=$(cat /config/gui_rpc_auth.cfg 2>/dev/null || echo "")
    boinccmd --passwd "$GUI_PASS" \
      --set_global_prefs "<global_preferences><ram_max_used_busy_pct>80</ram_max_used_busy_pct><ram_max_used_idle_pct>80</ram_max_used_idle_pct></global_preferences>" \
      2>/dev/null || true
    boinccmd --passwd "$GUI_PASS" \
      --project_attach "$PROJECT_URL" "$ACCOUNT_KEY" \
      2>/dev/null || true
    echo "BOINC attached to project: $PROJECT_URL"
  ' &>/dev/null &
fi
