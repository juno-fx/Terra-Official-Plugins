#!/bin/bash
set -e

# s6-overlay init script — runs before boinc-client starts
# Creates client_state.xml with project pre-configured

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

# Create client_state.xml with project pre-configured
if [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  cat > /config/client_state.xml <<EOF
<client_state>
  <project>
    <master_url>${PROJECT_URL}</master_url>
    <authenticator>${ACCOUNT_KEY}</authenticator>
    <resource_share>100</resource_share>
  </project>
</client_state>
EOF
fi
