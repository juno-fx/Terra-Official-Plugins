# PLUGIN

![PLUGIN]()

**Category:** <!-- TODO: e.g. AI · CG · Workstations · Data Science -->
**Type:** Workload Template
**Tags:** `workload` · `PLUGIN`

---

## Overview

<!-- TODO: 2–3 sentences. What does this workload template enable users to run? -->

---

## How It Works

**Workload Template** — Installs the PLUGIN workload schema into Genesis. Once installed, the PLUGIN type appears in **Genesis** on the Workloads page, where it can be authored into a workload template. Users can then launch and provision their own PLUGIN instance on demand within a project through **Hubble**.

---

## Prerequisites

- <!-- TODO: List prerequisites, e.g. NVIDIA GPU Operator (for GPU workloads), storage classes, Ollama plugin -->

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"PLUGIN"**
3. Click **Install**
4. Click **Confirm** to deploy (no install-time fields required)

Once installed, the PLUGIN schema is available in **Genesis**. From the Workloads page, author the template — users can then launch and provision PLUGIN instances on demand through **Hubble**.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

### Workload Launch Fields

These fields are configured when authoring the workload template in **Genesis** and used each time a user provisions a PLUGIN instance through **Hubble**:

| Field | Details |
|-------|---------|
| `registry` | **string** · Required · Default: `docker.io`<br>Container registry for the PLUGIN image |
| `repo` | **string** · Required · Default: `PLUGIN`<br>PLUGIN image repository |
| `tag` | **string** · Required · Default: `latest`<br>Image tag |
| `gpu` | **boolean** · Required<br>Enable GPU access for the workload |
| `publicAccess` | **boolean** · Required · Default: `false`<br>Disable authentication and allow unauthenticated access to the workload |

<!-- TODO: Add any extra fields from templates/metadata.yaml above, and remove fields that don't apply -->

### Custom Environment Variables

Genesis lets you add arbitrary environment variables to the workload at launch time. These are commonly useful for PLUGIN:

| Variable | Description |
|----------|--------------|
| `TODO_VAR_NAME` | <!-- TODO: what this variable does and when to set it --> |

<!-- TODO: Keep this table in sync with terra.yaml's `environment_variables` list. Only list the
     most commonly used variables for end users — not every variable the upstream image supports.
     If the image has none worth calling out, delete this subsection and set `environment_variables: []`
     in terra.yaml instead. -->

---

## Notes

- <!-- TODO: Add usage tips, image recommendations, storage notes, GPU requirements, etc. -->
