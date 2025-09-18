#!/bin/bash
set -e

if [ -n "$PLUGIN_CATALOG" ]; then
    echo "Catalog mode enabled (PLUGIN_CATALOG=$PLUGIN_CATALOG)"
    echo "Building changed plugins..."

    # Find plugins with changes (staged or unstaged)
    changed_plugins=$(git status --porcelain ./plugins/ | awk '{print $2}' | cut -d'/' -f2 | sort -u)

    if [ -z "$changed_plugins" ]; then
        echo "No plugin changes detected. Skipping packaging..."
    else
        for plugin in $changed_plugins; do
            echo "Packaging ${plugin}..."
            make --no-print-directory package "${plugin}"
            git add "./plugins/${plugin}/" || true
        done
    fi
else
    echo "Test Deploying Changes: ${PLUGIN_NAME}"
    make --no-print-directory package "${PLUGIN_NAME}"
    git add "./plugins/${PLUGIN_NAME}/" || true
fi

git commit || true

if [ -n "$PLUGIN_CATALOG" ]; then
    echo "Refresh the Terra App Store to see changes"
else
    # Clean hostname (strip off -N suffix, e.g. fred-0 -> fred)
    CLEAN_HOSTNAME=$(echo "$HOSTNAME" | cut -d'-' -f1)

    echo "Triggering argo refresh"
    kubectl patch -n argocd app "$PLUGIN_NAME-$CLEAN_HOSTNAME-dev" \
        --patch-file ./tests/sync-patch.yaml \
        --type merge
fi
