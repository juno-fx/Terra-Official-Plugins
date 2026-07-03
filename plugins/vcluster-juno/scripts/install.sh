#!/bin/bash
set -euo pipefail

: "${VCLUSTER_NAME:?VCLUSTER_NAME is required}"
: "${VCLUSTER_NAMESPACE:?VCLUSTER_NAMESPACE is required}"
: "${VCLUSTER_SERVER:?VCLUSTER_SERVER is required}"
: "${ARGOCD_MANIFEST_URL:?ARGOCD_MANIFEST_URL is required}"
: "${JUNO_APP_FILE:?JUNO_APP_FILE is required}"

KUBECONFIG_SECRET="vc-${VCLUSTER_NAME}"
VC_KUBECONFIG=/tmp/vc-kubeconfig
VC="kubectl --kubeconfig=${VC_KUBECONFIG}"

retry() {
    local attempts="$1" delay="$2"
    shift 2
    local i
    for ((i = 1; i <= attempts; i++)); do
        if "$@"; then
            return 0
        fi
        echo "  attempt ${i}/${attempts} failed: $* — retrying in ${delay}s"
        sleep "${delay}"
    done
    echo "ERROR: giving up after ${attempts} attempts: $*"
    return 1
}

echo "==> Waiting for vCluster kubeconfig secret ${VCLUSTER_NAMESPACE}/${KUBECONFIG_SECRET}..."
retry 60 10 kubectl get secret "${KUBECONFIG_SECRET}" -n "${VCLUSTER_NAMESPACE}" -o name

kubectl get secret "${KUBECONFIG_SECRET}" -n "${VCLUSTER_NAMESPACE}" \
    -o jsonpath='{.data.config}' | base64 -d > "${VC_KUBECONFIG}"

# The exported kubeconfig server is set by the chart's exportKubeConfig.server,
# but guard against older charts that leave it pointing at localhost:8443.
if grep -q "localhost" "${VC_KUBECONFIG}"; then
    echo "==> Rewriting kubeconfig server to ${VCLUSTER_SERVER}"
    CLUSTER_NAME=$(${VC} config view -o jsonpath='{.clusters[0].name}')
    ${VC} config set-cluster "${CLUSTER_NAME}" --server="${VCLUSTER_SERVER}"
fi

echo "==> Waiting for vCluster API to become ready..."
retry 60 10 ${VC} get --raw=/readyz

echo "==> Creating argocd namespace inside the vCluster..."
${VC} create namespace argocd --dry-run=client -o yaml | ${VC} apply -f -

# Server-side apply is required: the ApplicationSet CRD manifest exceeds the
# 256KB last-applied-configuration annotation limit and gets silently rejected
# by client-side apply, leaving the applicationset-controller crash-looping.
echo "==> Installing ArgoCD inside the vCluster (server-side apply)..."
retry 5 15 ${VC} apply --server-side --force-conflicts -n argocd -f "${ARGOCD_MANIFEST_URL}"

echo "==> Verifying ArgoCD CRDs are registered..."
for crd in applications.argoproj.io appprojects.argoproj.io applicationsets.argoproj.io; do
    retry 12 10 ${VC} get crd "${crd}" -o name
done

echo "==> Waiting for ArgoCD workloads to roll out..."
for deploy in $(${VC} get deployments -n argocd -o name); do
    ${VC} rollout status "${deploy}" -n argocd --timeout=600s
done
${VC} rollout status statefulset/argocd-application-controller -n argocd --timeout=600s

# Controllers can briefly report Running before crashing on a missing CRD —
# confirm they survive past their startup window before declaring success.
echo "==> Verifying ArgoCD pods stay healthy for 30s..."
sleep 30
NOT_READY=$(${VC} get pods -n argocd --no-headers | awk '{split($2, r, "/"); if (r[1] != r[2] || $3 != "Running") print $1}' || true)
if [ -n "${NOT_READY}" ]; then
    echo "ERROR: ArgoCD pods not healthy after stabilization window:"
    echo "${NOT_READY}"
    ${VC} get pods -n argocd
    exit 1
fi

if [ "${LABEL_NODES:-true}" = "true" ]; then
    # The Juno charts pin services to juno-innovations.com/service=true and
    # workloads to juno-innovations.com/workstation=true. Nodes inside the
    # vCluster (virtual or synced) don't carry these labels by default.
    echo "==> Labeling vCluster nodes for Juno scheduling..."
    retry 12 10 bash -c "[ \$(${VC} get nodes --no-headers 2>/dev/null | wc -l) -gt 0 ]"
    ${VC} label nodes --all "juno-innovations.com/service=true" --overwrite
    ${VC} label nodes --all "juno-innovations.com/workstation=true" --overwrite
fi

echo "==> Deploying Juno (ArgoCD Application) inside the vCluster..."
${VC} apply -f "${JUNO_APP_FILE}"

echo "==> Waiting for the Juno Application to be picked up..."
retry 30 10 ${VC} get application juno -n argocd -o name

echo "==> Current Juno Application state:"
${VC} get application juno -n argocd \
    -o jsonpath='sync: {.status.sync.status}{"\n"}health: {.status.health.status}{"\n"}' || true

echo "==> vcluster-juno install complete."
echo "    ArgoCD inside the vCluster will continue syncing the Juno stack."
echo "    The Juno UI ingress will be synced to the host ingress controller once ready."
