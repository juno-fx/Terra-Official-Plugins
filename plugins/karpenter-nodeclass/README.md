# Karpenter EC2NodeClass

![Karpenter EC2NodeClass](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/plugins/karpenter-nodeclass/assets/logo.png?raw=true)

**Category:** Compute
**Type:** Cluster Service
**Tags:** `karpenter` · `autoscaling` · `ec2` · `aws` · `cluster-level`

---

## Overview

The Karpenter EC2NodeClass plugin configures the AWS-specific node template that Karpenter uses when provisioning EC2 instances. It defines which IAM role, subnets, security groups, EBS volume configuration, and AMI Karpenter uses when launching nodes. This is the foundation that all Karpenter NodePools build on — install this once per cluster, then install `karpenter-nodepool` one or more times to define your scaling policies.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. The install name becomes the EC2NodeClass resource name in Kubernetes. Other plugins reference this name via their `nodeclass_ref` field.

Subnet and security group discovery is automatic — Karpenter finds them by the `karpenter.sh/discovery` tag on your AWS resources, which must be set to your cluster name.

---

## Prerequisites

- EKS cluster with Karpenter installed (e.g. via `eksctl` with the `karpenter` addon)
- EC2 subnets and security groups tagged with `karpenter.sh/discovery: <cluster-name>`
- A Karpenter Node IAM role attached to your cluster

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Karpenter EC2NodeClass"**
3. Click **Install**
4. Choose an install name — this becomes the EC2NodeClass resource name (e.g. `default`)
5. Fill in the configuration fields below
6. Click **Confirm** to deploy

After installation, use this plugin's install name as the `nodeclass_ref` when installing `karpenter-nodepool`.

---

## Configuration

### Install-Time Fields

| Field | Details |
|-------|---------|
| `cluster_name` | **string** · Required<br>Your EKS cluster name. Must match the `karpenter.sh/discovery` tag on your cluster's subnets and security groups. |
| `role` | **string** · Required<br>IAM role name for Karpenter-provisioned nodes. Find it with: `aws iam list-roles --query "Roles[?contains(RoleName, 'KarpenterNodeRole')].RoleName" --output text` |
| `volume_size` | **string** · Required · Default: `100Gi`<br>Root EBS volume size for provisioned nodes. |
| `volume_type` | **select** · Required · Default: `gp3`<br>Root EBS volume type. Options: `gp3`, `gp2`, `io1`, `io2`. |
| `ami_alias` | **string** · Required · Default: `al2023@latest`<br>AMI selector alias. Controls which Amazon Machine Image nodes boot from. Use `al2023@latest` for the latest Amazon Linux 2023, or pin to a specific version. |

---

## Notes

- Most clusters only need one EC2NodeClass. Install multiple only if NodePools need meaningfully different node configurations (e.g. different volume sizes or IAM roles)
- The `amiFamily` is hardcoded to `AL2023` — change the `ami_alias` field to control the exact AMI version, not the family
- Subnets and security groups are discovered automatically by Karpenter using the `karpenter.sh/discovery` tag — no explicit subnet or security group IDs are required
- After installing, proceed to install `karpenter-nodepool` to define your node scaling policies
