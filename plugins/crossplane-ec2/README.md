# Crossplane EC2

![Crossplane EC2](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/crossplane-ec2/scripts/assets/logo.png)

**Category:** Virtual Machine
**Type:** Workload Template
**Tags:** `virtualization` · `virtual-machine` · `crossplane` · `AWS`
**Compatibility:** `genesis-deployment>=3.0.2` · `orion-deployment>=3.1.0`

---

## Overview

Crossplane EC2 is a workload template that lets you launch and manage AWS EC2 instances directly from the Genesis workload UI. It installs a Crossplane Composition and XRD (Composite Resource Definition) that Kuiper uses to provision EC2 instances on demand — giving cloud VMs the same lifecycle management as containerized workstations. Once launched, Kuiper tracks the EC2 instance and automatically exposes its endpoints in the Hubble UI.

This plugin requires **Crossplane** and **Crossplane AWS Provider** to be installed first.

---

## Plugin Type

**Workload Template** — Installed into the `argocd` namespace. At install time, a schema ConfigMap is created that Genesis reads to show EC2 workload options in the workload creation UI. EC2 instances are provisioned when a user launches a workload — not at plugin install time.

---

## Prerequisites

- **Crossplane** plugin installed
- **Crossplane AWS Provider** plugin installed and configured with valid AWS credentials
- An AWS VPC, subnet, and security groups already configured in AWS
- Platform versions: `genesis-deployment >= 3.0.2`, `orion-deployment >= 3.1.0`

---

## Installation

1. Install the **Crossplane** and **Crossplane AWS Provider** plugins first
2. Open **Terra** and navigate to the **Plugin Marketplace**
3. Search for **"Crossplane EC2"**
4. Click **Install**
5. Click **Confirm** to deploy (no install-time fields required)

Once installed, the EC2 workload type will appear in Genesis when creating new workloads.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are filled in when launching an EC2 workload in **Genesis**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `ami_image_id` | string | **Yes** | — | AWS AMI image ID for the EC2 instance |
| `security_group_ids` | list | **Yes** | — | List of AWS security group IDs to attach |
| `block_device_mappings` | list | **Yes** | — | Block devices to attach (mount path + size in GB) |
| `subnet_id` | string | **Yes** | — | AWS Subnet ID for the instance |
| `instance_type` | string | **Yes** | `t3.micro` | EC2 instance type (e.g. `t3.medium`, `m5.large`) |
| `delete_on_termination` | boolean | **Yes** | `true` | Whether to delete EBS volumes when the instance is terminated |
| `region` | string | **Yes** | — | AWS region to launch the instance in (e.g. `us-east-1`) |
| `provider_config_ref` | string | **Yes** | `aws-provider-argocd-provider-config` | Name of the Crossplane ProviderConfig to use |

---

## Notes

- EC2 instances launched by this plugin are tracked by Kuiper; stopping a workload in Genesis will terminate the EC2 instance
- The `delete_on_termination` field controls whether EBS volumes are destroyed with the instance — set to `false` to preserve data across launches
- Network endpoints (SSH, RDP, etc.) are automatically discovered by Kuiper once the EC2 instance is running and surfaced in Hubble
