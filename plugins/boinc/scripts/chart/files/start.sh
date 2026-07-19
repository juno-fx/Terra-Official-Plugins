#!/bin/sh
set -e

# Write cc_config with CPU limit from cgroup
echo "<cc_config>
  <options>
    <ncpus>$(awk '{print int($1/100000)}' /sys/fs/cgroup/cpu.max 2>/dev/null || nproc)</ncpus>
  </options>
</cc_config>" > /var/lib/boinc/cc_config.xml

# Start boinc (it writes its own logs to stdoutdae.txt in data dir)
boinc &
sleep 5

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
boinccmd --project_attach "${PROJECT_URL}" "${ACCOUNT_KEY}" 2>/dev/null || true
echo "BOINC started"

wait
