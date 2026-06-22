# Crossplane AWS Provider

![Crossplane AWS Provider](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/crossplane/assets/logo.png)

**Category:** Cloud Management
**Type:** Cluster-Level Plugin
**Tags:** `crossplane` · `cloud` · `control-plane` · `AWS`
**Editable:** Yes

---

## Overview

The Crossplane AWS Provider enables Kubernetes to provision and manage AWS resources — EC2 instances, S3 buckets, RDS databases, VPCs, and more — directly through the Kubernetes API. It reads AWS credentials from a Kubernetes Secret that you pre-create in the cluster, then uses those credentials to make AWS API calls on behalf of your compositions and claims.

This plugin requires **Crossplane** to be installed first. You will also need an AWS credentials secret in your cluster before installation.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. The AWS Provider installs cluster-scoped CRDs for all supported AWS resource types and connects to AWS using the configured secret.

---

## Prerequisites

- **Crossplane** plugin installed in the cluster
- An AWS credentials Kubernetes Secret pre-created in your cluster

To create the AWS credentials secret:
```bash
kubectl create secret generic aws-credentials \
  --from-literal=credentials="[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY" \
  -n <your-namespace>
```

See the [Kubernetes Secrets documentation](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/) for more options.

---

## Installation

1. Install the **Crossplane** plugin first
2. Create your AWS credentials secret in the cluster
3. Open **Terra** and navigate to the **Plugin Marketplace**
4. Search for **"Crossplane AWS Provider"**
5. Click **Install**
6. Fill in the configuration fields below
7. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | No | `v0.55.0` | Version of the Crossplane AWS Provider to install |
| `secret_namespace` | string | **Yes** | — | Namespace where your AWS credentials secret is stored |
| `secret_name` | string | **Yes** | — | Name of the Kubernetes Secret containing AWS credentials |
| `secret_key` | string | **Yes** | — | Key within the secret that holds the credentials file content |

---

## Notes

- This plugin is **editable** — you can update secret references and provider version after initial install via Terra
- The AWS Provider supports a wide range of AWS services; see the [Crossplane AWS Provider documentation](https://marketplace.upbound.io/providers/upbound/provider-aws/) for the full resource catalog
- Never store AWS credentials directly in `terra.yaml` values — always reference a Kubernetes Secret
