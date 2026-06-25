# Velero

![Velero](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/velero/assets/logo.png)

**Category:** Infrastructure
**Type:** Cluster Service
**Tags:** `backup`

---

## Overview

Velero is an open-source Kubernetes backup and restore operator that protects your cluster's Kubernetes API resources and persistent volumes. It stores backups in S3-compatible object storage, supports scheduled backups, and enables disaster recovery and cluster migration scenarios. Velero is the foundational plugin required before deploying the **Velero Cluster Backup** schedule.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, Velero can back up any resource in the cluster and store them in the S3 bucket you configure.

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

| Field | Details |
|-------|---------|
| `chart_version` | **string** · Required · Default: `11.1.1`<br>Velero Helm chart version to install |
| `bucket` | **string** · Required<br>Name of the S3 bucket to store backups in |
| `region` | **string** · Optional<br>AWS region or storage provider region (e.g. `us-east-1`). Required for AWS S3; consult your provider's docs for other S3-compatible systems. |
| `s3Url` | **string** · Required · Default: `https://s3.us-east-2.amazonaws.com`<br>S3-compatible storage endpoint URL |
| `access_key_id` | **string** · Required<br>Access key ID for S3 authentication |
| `secret_access_key` | **string** · Required<br>Secret access key for S3 authentication |

---

## Notes

- Once Velero is installed, deploy the **Velero Cluster Backup** plugin to schedule automatic backups
- Velero backs up Kubernetes API resources (Pods, Deployments, Services, etc.) — for volume data backup, additional configuration is required (volume snapshots or Restic/Kopia integration)
- The `s3Url` field should point to the correct regional endpoint; for MinIO, use your MinIO server URL (e.g. `http://minio.example.com:9000`)
- Backups can be initiated on demand via the Velero CLI or scheduled via the **Velero Cluster Backup** plugin
