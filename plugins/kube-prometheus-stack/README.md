# Kubernetes Prometheus Stack

![Kubernetes Prometheus Stack](https://raw.githubusercontent.com/juno-fx/Terra-Official-Plugins/refs/heads/main/plugins/kube-prometheus-stack/assets/logo.png)

**Category:** Monitoring
**Type:** Cluster-Level Plugin
**Tags:** `prometheus` · `grafana` · `alertmanager` · `dashboard`

---

## Overview

The Kubernetes Prometheus Stack deploys the full Prometheus monitoring ecosystem into your cluster — including Prometheus for metrics collection, Grafana for visualization and dashboards, and Alertmanager for alerting. This is the standard observability stack used in production Kubernetes environments, pre-configured with Kubernetes-specific dashboards and service monitors that immediately begin collecting cluster metrics upon installation.

---

## Plugin Type

**Cluster-Level Plugin** — Installed into the `argocd` namespace. The Prometheus stack monitors the entire cluster and is shared across all projects and namespaces.

---

## Prerequisites

- A DNS record pointing to your cluster's ingress controller for the Grafana host
- An nginx ingress controller configured in the cluster
- Sufficient cluster resources — Prometheus and its components have non-trivial memory requirements in larger clusters

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Kubernetes Prometheus Stack"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `username` | string | **Yes** | — | Grafana admin username |
| `password` | string | **Yes** | — | Grafana admin password |
| `host` | string | **Yes** | — | Hostname for the Grafana dashboard (e.g. `grafana.example.com`). A DNS record pointing to your cluster's ingress must exist. |
| `path` | string | No | — | URL sub-path for Grafana (e.g. `/grafana`) if serving under a sub-path |

---

## Notes

- The Grafana admin credentials set here are the initial login credentials — you can create additional users within Grafana after installation
- Prometheus scrapes metrics from all namespaces and includes pre-built Kubernetes dashboards for nodes, pods, deployments, and cluster health
- Alertmanager can be configured via Grafana or PrometheusRule CRDs to send alerts to Slack, PagerDuty, email, and other destinations
- This is a resource-intensive stack — monitor cluster node capacity before installing on smaller clusters
