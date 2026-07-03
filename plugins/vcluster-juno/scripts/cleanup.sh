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

# ArgoCD drops the app finalizer without reliably reaping PostDelete hook
# resources. Parent them to this Job so garbage collection removes them
# when the Job is TTL-reaped (ttlSecondsAfterFinished).
echo "==> Parenting hook resources to the cleanup Job for GC..."
JOB_NAME="${VCLUSTER_NAME}-cleanup"
JOB_UID=$(kubectl get job "${JOB_NAME}" -n "${VCLUSTER_NAMESPACE}" -o jsonpath='{.metadata.uid}' 2>/dev/null || true)
if [ -n "${JOB_UID}" ]; then
    OWNER_PATCH="{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"batch/v1\",\"kind\":\"Job\",\"name\":\"${JOB_NAME}\",\"uid\":\"${JOB_UID}\"}]}}"
    for res in "configmap/${VCLUSTER_NAME}-scripts-configmap-cleanup" \
               "rolebinding.rbac.authorization.k8s.io/${JOB_NAME}" \
               "role.rbac.authorization.k8s.io/${JOB_NAME}" \
               "serviceaccount/${JOB_NAME}"; do
        kubectl patch "${res}" -n "${VCLUSTER_NAMESPACE}" --type merge -p "${OWNER_PATCH}" || true
    done
else
    echo "WARNING: could not resolve own Job UID — hook resources will linger."
fi

echo "==> vcluster-juno cleanup complete."
