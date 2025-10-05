#!/bin/bash

set -e

ARGOCD_NAMESPACE=argocd

remove_configmap_key() {
    local cm_name="$1"
    local key="$2"
    
    echo "Removing key '${key}' from ConfigMap ${cm_name}"
    
    if ! kubectl get configmap "${cm_name}" -n "${ARGOCD_NAMESPACE}" >/dev/null 2>&1; then
        echo "ConfigMap ${cm_name} does not exist, skipping..."
        return 0
    fi
    
    if ! kubectl get configmap "${cm_name}" -n "${ARGOCD_NAMESPACE}" -o jsonpath="{.data.${key}}" >/dev/null 2>&1; then
        echo "Key '${key}' does not exist in ConfigMap ${cm_name}, skipping..."
        return 0
    fi
    
    kubectl patch configmap "${cm_name}" -n "${ARGOCD_NAMESPACE}" \
        --type json \
        -p "[{\"op\": \"remove\", \"path\": \"/data/${key}\"}]"
}

echo "Cleaning up ArgoCD ConfigMaps..."

echo "Cleaning argocd-cm..."
remove_configmap_key "argocd-cm" "users.anonymous.enabled"

echo "Cleaning argocd-cmd-params-cm..."
remove_configmap_key "argocd-cmd-params-cm" "server.rootpath"
remove_configmap_key "argocd-cmd-params-cm" "server.disable.auth"
remove_configmap_key "argocd-cmd-params-cm" "server.x.frame.options"

echo "Cleaning argocd-rbac-cm..."

echo "ArgoCD ConfigMaps cleanup completed successfully!"
