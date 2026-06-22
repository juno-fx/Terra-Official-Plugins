# Velero Cluster Backup

<img src="https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/velero/assets/logo.png" alt="Velero Cluster Backup" width="80" />

**Category:** Infrastructure
**Type:** Cluster Service
**Tags:** `backup`

---

## Overview

Velero Cluster Backup creates a scheduled, automated backup of all Kubernetes API resources in your cluster using Velero. It configures a `Schedule` resource that triggers backups on a cron schedule and automatically rotates old backups after a configurable retention period. This plugin depends on the **Velero** plugin being installed and configured first.

> **Note:** This plugin backs up **Kubernetes API resources only** (Pods, Deployments, Services, ConfigMaps, etc.). It does **not** back up data stored in Persistent Volumes unless Velero is configured with volume snapshot support separately.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, automated backups run on the schedule you define and are stored in the S3 bucket configured in the Velero plugin.

---

## Prerequisites

- **Velero** plugin installed and configured with a working S3 storage backend
- Velero must be able to successfully create manual backups before scheduling automated ones

---

## Installation

1. Install the **Velero** plugin first
2. Verify Velero can reach the S3 bucket by creating a test backup (optional but recommended)
3. Open **Terra** and navigate to the **Plugin Marketplace**
4. Search for **"Velero Cluster Backup"**
5. Click **Install**
6. Fill in the configuration fields below
7. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `schedule` | **string** · Optional · Default: `0 7 * * *`<br>Cron expression defining when to run backups. Default: daily at 7:00 AM UTC. |
| `retention` | **string** · Optional · Default: `720h0m0s`<br>Duration after which old backups are deleted. Default: 30 days (`720h0m0s`). |

---

## Notes

- The `schedule` field uses standard cron syntax (`minute hour day month weekday`). Examples:
  - `0 7 * * *` — daily at 7:00 AM UTC
  - `0 */6 * * *` — every 6 hours
  - `0 2 * * 0` — weekly on Sunday at 2:00 AM UTC
- The `retention` duration uses Go duration format: `720h0m0s` (30 days), `168h0m0s` (7 days)
- Backup data is stored in the S3 bucket configured in the **Velero** plugin
- To restore from a backup, use the Velero CLI: `velero restore create --from-backup <backup-name>`
