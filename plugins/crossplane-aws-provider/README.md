# Crossplane AWS Provider

![Crossplane AWS Provider](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/crossplane/assets/logo.png)

**Category:** Cloud Management
**Type:** Cluster Service
**Tags:** `crossplane` · `cloud` · `control-plane` · `AWS`
**Editable:** Yes

---

## Overview

The Crossplane AWS Provider enables Kubernetes to provision and manage AWS resources — EC2 instances, S3 buckets, RDS databases, VPCs, and more — directly through the Kubernetes API. It reads AWS credentials from a Kubernetes Secret that you pre-create in the cluster, then uses those credentials to make AWS API calls on behalf of your compositions and claims.

This plugin requires **Crossplane** to be installed first. You will also need an AWS credentials secret in your cluster before installation.

---

## How It Works

**Cluster Service** — Installed once per cluster by an administrator. Once active, Crossplane can provision and manage AWS resources on behalf of the whole cluster using the credentials you provide.

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

## Recommended AWS IAM Policies

> **Reference only:** these policies are examples, not a supported or complete configuration. Review them against your own security requirements and adjust them for your environment before use.

Use a dedicated IAM user (no console access) for the credentials secret, ideally in a dedicated AWS account for Juno workloads.

### Crossplane EC2 (`crossplane-ec2`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyLookups",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ManageInstanceLifecycle",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:ModifyInstanceAttribute",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": { "aws:RequestedRegion": ["us-east-1"] }
      }
    }
  ]
}
```

Replace `us-east-1` with your region(s), or remove the `Condition` block. Encrypted EBS volumes using a customer-managed KMS key also need KMS permissions on that key.

If a permission is missing, `kubectl describe instance.ec2.aws.crossplane.io <name>` shows an `UnauthorizedOperation` error naming the denied action.

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

| Field | Details |
|-------|---------|
| `version` | **string** · Optional · Default: `v0.55.0`<br>Version of the Crossplane AWS Provider to install |
| `secret_namespace` | **string** · Required<br>Namespace where your AWS credentials secret is stored |
| `secret_name` | **string** · Required<br>Name of the Kubernetes Secret containing AWS credentials |
| `secret_key` | **string** · Required<br>Key within the secret that holds the credentials file content |

---

## Notes

- This plugin is **editable** — you can update secret references and provider version after initial install via Terra
- The AWS Provider supports a wide range of AWS services; see the [Crossplane AWS Provider documentation](https://marketplace.upbound.io/providers/upbound/provider-aws/) for the full resource catalog
- Never store AWS credentials directly in `terra.yaml` values — always reference a Kubernetes Secret
