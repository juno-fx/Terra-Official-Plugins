# Crossplane EC2

![Crossplane EC2](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/crossplane-ec2/scripts/assets/logo.png)

**Category:** Virtual Machine
**Type:** Workload Template
**Tags:** `virtualization` · `virtual-machine` · `crossplane` · `AWS`
**Compatibility:** `genesis-deployment>=3.0.2` · `orion-deployment>=3.1.0`

---

## Overview

Crossplane EC2 is a workload template that lets you launch and manage AWS EC2 instances directly from the Genesis workload screen — giving cloud VMs the same lifecycle management as containerised workstations. Once launched, endpoints like SSH and RDP are automatically discovered and surfaced in Hubble.

This plugin requires **Crossplane** and **Crossplane AWS Provider** to be installed first.

---

## How It Works

**Workload Template** — Adds an EC2 workload type to Genesis. Once installed, users can launch AWS EC2 instances directly from the Genesis workload screen. Each instance is provisioned on demand and tracked in Hubble like any other workload.

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

| Field | Details |
|-------|---------|
| `ami_image_id` | **string** · Required<br>AWS AMI image ID for the EC2 instance |
| `security_group_ids` | **list** · Required<br>List of AWS security group IDs to attach |
| `block_device_mappings` | **list** · Required<br>Block devices to attach (mount path + size in GB) |
| `subnet_id` | **string** · Required<br>AWS Subnet ID for the instance |
| `instance_type` | **string** · Required · Default: `t3.micro`<br>EC2 instance type (e.g. `t3.medium`, `m5.large`) |
| `delete_on_termination` | **boolean** · Required · Default: `true`<br>Whether to delete EBS volumes when the instance is terminated |
| `region` | **string** · Required<br>AWS region to launch the instance in (e.g. `us-east-1`) |
| `provider_config_ref` | **string** · Required · Default: `aws-provider-argocd-provider-config`<br>Name of the Crossplane ProviderConfig to use |

---

## Notes

- EC2 instances are tracked as workloads — stopping a workload in Genesis will terminate the EC2 instance
- The `delete_on_termination` field controls whether EBS volumes are destroyed with the instance — set to `false` to preserve data across launches
- Network endpoints (SSH, RDP, etc.) are automatically discovered once the EC2 instance is running and surfaced in Hubble
