# Velero

![Velero](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/velero/assets/logo.png)

**Category:** Infrastructure
**Type:** Cluster-Level Plugin
**Tags:** `backup`

---

## Overview

Velero is an open-source Kubernetes backup and restore operator that protects your cluster's Kubernetes API resources and persistent volumes. It stores backups in S3-compatible object storage, supports scheduled backups, and enables disaster recovery and cluster migration scenarios. Velero is the foundational plugin required before deploying the **Velero Cluster Backup** schedule.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. Velero manages cluster-scoped backup resources and connects to your S3 storage backend.

---

## Prerequisites

- An S3-compatible storage bucket (AWS S3, MinIO, Backblaze B2, etc.) and credentials with read/write access to it
- The bucket must exist before installing Velero — it will not be created automatically

---

## Installation

1. Create an S3-compatible bucket for backup storage
2. Open **Terra** and navigate to the **Plugin Marketplace**
3. Search for **"Velero"**
4. Click **Install**
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `chart_version` | string | **Yes** | `11.1.1` | Velero Helm chart version to install |
| `bucket` | string | **Yes** | — | Name of the S3 bucket to store backups in |
| `region` | string | No | — | AWS region or storage provider region (e.g. `us-east-1`). Required for AWS S3; consult your provider's docs for other S3-compatible systems. |
| `s3Url` | string | **Yes** | `https://s3.us-east-2.amazonaws.com` | S3-compatible storage endpoint URL |
| `access_key_id` | string | **Yes** | — | Access key ID for S3 authentication |
| `secret_access_key` | string | **Yes** | — | Secret access key for S3 authentication |

---

## Notes

- Once Velero is installed, deploy the **Velero Cluster Backup** plugin to schedule automatic backups
- Velero backs up Kubernetes API resources (Pods, Deployments, Services, etc.) — for volume data backup, additional configuration is required (volume snapshots or Restic/Kopia integration)
- The `s3Url` field should point to the correct regional endpoint; for MinIO, use your MinIO server URL (e.g. `http://minio.example.com:9000`)
- Backups can be initiated on demand via the Velero CLI or scheduled via the **Velero Cluster Backup** plugin
