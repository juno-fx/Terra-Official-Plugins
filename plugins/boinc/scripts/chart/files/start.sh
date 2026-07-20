#!/bin/bash
set -e

# s6-overlay init script — runs in background so services aren't blocked
# Attaches BOINC client to a project using PROJECT_URL and ACCOUNT_KEY
# Also applies CPU/memory limits from cgroup

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

# Fork attach into background — boinc client may not be ready yet
if [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  (
    # Wait for boinc client RPC socket
    for i in $(seq 1 30); do
      if boinccmd --get_state > /dev/null 2>&1; then
        break
      fi
      sleep 2
    done

    # Set memory limit from cgroup (BOINC only supports percentage)
    MEM_BYTES=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo 0)
    TOTAL_MEM=$(awk '/^MemTotal:/{print int($2)}' /proc/meminfo)
    if [ "$MEM_BYTES" -gt 0 ] && [ "$MEM_BYTES" != "max" ]; then
      TARGET_MB=$(( MEM_BYTES / 1048576 * 80 / 100 ))
      PCT=$(( TARGET_MB * 1024 * 100 / TOTAL_MEM ))
      [ "$PCT" -gt 90 ] && PCT=90
      [ "$PCT" -lt 5 ] && PCT=5
      boinccmd --set_global_prefs "<global_preferences><ram_max_used_busy_pct>${PCT}</ram_max_used_busy_pct><ram_max_used_idle_pct>${PCT}</ram_max_used_idle_pct></global_preferences>" 2>/dev/null || true
    fi

    # Attach to project
    boinccmd --project_attach "$PROJECT_URL" "$ACCOUNT_KEY" 2>/dev/null || true
    echo "BOINC attached to project: $PROJECT_URL"
  ) &
fi
