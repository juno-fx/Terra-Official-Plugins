#!/bin/bash
set -e

# s6-overlay init script — runs before boinc-client starts
# Injects project into client_state.xml so boinc-client sees it immediately on startup

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

# Inject project into client_state.xml before boinc-client starts
if [ -n "$PROJECT_URL" ] && [ -n "$ACCOUNT_KEY" ]; then
  # Remove the original closing tag, then append project block with new closing tag
  sed -i '/<\/client_state>/d' /config/client_state.xml
  cat >> /config/client_state.xml <<EOF
  <project>
    <master_url>${PROJECT_URL}</master_url>
    <authenticator>${ACCOUNT_KEY}</authenticator>
    <resource_share>100</resource_share>
  </project>
</client_state>
EOF
fi
