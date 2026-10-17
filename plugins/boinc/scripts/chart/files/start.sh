#!/usr/bin/with-contenv bash
set -e

# s6-overlay init script — runs before boinc-client starts
# Injects project into client_state.xml so boinc sees it immediately
# (s6-rc uses a compiled database, modifying service run files has no effect)

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
  <suspend_cpu_usage>0</suspend_cpu_usage>
</global_preferences>
PREFS
chown abc:abc /config/global_prefs_override.xml

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
