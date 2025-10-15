#!/bin/bash

set -e

ARGOCD_NAMESPACE=argocd

# Check if PREFIX is set and not empty
if [[ -z "${PREFIX:-}" ]]; then
    echo "ERROR: PREFIX environment variable must be set and not empty"
    exit 1
fi

patch_configmap() {
    local cm_name="$1"
    local key="$2"
    local value="$3"
    
    echo "Patching ConfigMap ${cm_name} with ${key}=${value}"
    
    kubectl patch configmap "${cm_name}" -n "${ARGOCD_NAMESPACE}" \
        --type merge \
        -p "{\"data\":{\"${key}\":\"${value}\"}}"
}

echo "Configuring ArgoCD ConfigMaps..."

echo "Updating argocd-cm..."
patch_configmap "argocd-cm" "admin.enabled" "true"
patch_configmap "argocd-cm" "users.anonymous.enabled" "true"

echo "Updating argocd-cmd-params-cm..."
patch_configmap "argocd-cmd-params-cm" "server.rootpath" "${PREFIX}"
patch_configmap "argocd-cmd-params-cm" "server.disable.auth" "true"
patch_configmap "argocd-cmd-params-cm" "server.x.frame.options" "allow-from *"

echo "Updating argocd-rbac-cm..."
patch_configmap "argocd-rbac-cm" "policy.default" "role:admin"

echo "ArgoCD ConfigMaps configuration completed successfully!"

kubectl rollout restart deployment argocd-server -n "${ARGOCD_NAMESPACE}"
