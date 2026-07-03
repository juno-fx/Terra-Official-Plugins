#!/bin/bash
set -uo pipefail

: "${VCLUSTER_NAME:?VCLUSTER_NAME is required}"
: "${VCLUSTER_NAMESPACE:?VCLUSTER_NAMESPACE is required}"

# The nested ArgoCD Application (<release>-vcluster) carries a resources
# finalizer, so ArgoCD cascade-deletes the vCluster chart resources when the
# plugin is uninstalled. The project namespace itself is left untouched —
# this hook only sweeps what the cascade doesn't cover: the StatefulSet's
# data PVC and the exported kubeconfig secrets.

echo "==> Deleting vCluster data PVCs..."
kubectl delete pvc -n "${VCLUSTER_NAMESPACE}" \
    -l "release=${VCLUSTER_NAME}" --ignore-not-found --wait=false
kubectl delete pvc -n "${VCLUSTER_NAMESPACE}" \
    "data-${VCLUSTER_NAME}-0" --ignore-not-found --wait=false

echo "==> Deleting exported kubeconfig secrets..."
kubectl delete secret -n "${VCLUSTER_NAMESPACE}" \
    "vc-${VCLUSTER_NAME}" --ignore-not-found
kubectl delete secret -n "${VCLUSTER_NAMESPACE}" \
    "vc-config-${VCLUSTER_NAME}" --ignore-not-found

echo "==> vcluster-juno cleanup complete."
