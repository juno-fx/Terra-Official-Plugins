#!/bin/bash
set -e

if [ -n "$PLUGIN_CATALOG" ]; then
    echo "Catalog mode enabled (PLUGIN_CATALOG=$PLUGIN_CATALOG)"
    echo "Building all plugins..."
    for dir in ./plugins/*/; do
        plugin=$(basename "$dir")
        echo "Packaging ${plugin}..."
        make --no-print-directory package "${plugin}"
        git add "$dir" || true
    done
else
    echo "Test Deploying Changes: ${PLUGIN_NAME}"
    make --no-print-directory package "${PLUGIN_NAME}"
    git add "./plugins/${PLUGIN_NAME}/" || true
fi

git commit || true

if [ -n "$PLUGIN_CATALOG" ]; then
    echo "Refresh the Terra App Store to see changes"
else
    echo "Triggering argo refresh"
    kubectl patch -n argocd app "${PLUGIN_NAME}" \
        --patch-file ./tests/sync-patch.yaml \
        --type merge
fi


