# Crossplane

![Crossplane](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/crossplane/assets/logo.png)

**Category:** Cloud Management
**Type:** Cluster-Level Plugin
**Tags:** `crossplane` · `cloud` · `control-plane`

---

## Overview

Crossplane is an open-source Kubernetes add-on that transforms your cluster into a universal control plane. It lets you provision and manage cloud infrastructure (AWS, GCP, Azure, and more) using native Kubernetes APIs and GitOps workflows — no separate infrastructure tooling required. Crossplane is the foundation required before installing any Crossplane provider plugins such as **Crossplane AWS Provider** or **Crossplane EC2**.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. Crossplane installs cluster-scoped `CustomResourceDefinitions` and controllers that manage cloud resources across all projects.

---

## Prerequisites

- A Kubernetes cluster with sufficient permissions to install CRDs and cluster-scoped RBAC resources
- This plugin must be installed **before** any Crossplane provider plugins (e.g. Crossplane AWS Provider)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Crossplane"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | No | `v2.1.4` | Version of Crossplane to install |

---

## Notes

- Crossplane alone does not provision any cloud resources — you must install a **provider** plugin (such as **Crossplane AWS Provider**) and configure credentials before cloud resources can be managed
- The default version (`v2.1.4`) is tested and recommended; only change this if you have a specific compatibility requirement
- See the [Crossplane documentation](https://docs.crossplane.io/) for provider setup and composition authoring
