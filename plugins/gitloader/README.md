# Git Loader

![Git Loader](https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png)

**Category:** Utility
**Type:** Namespaced Plugin
**Tags:** `git` · `loader` · `repository` · `clone`

---

## Overview

The Git Loader plugin clones a Git repository from any Git source into a shared persistent volume in your project. It is useful for seeding shared volumes with configuration files, project assets, scripts, or source code — making them immediately available to workstations without manual setup. Simply point it at a repository URL and branch, and it will clone the specified ref to the target path.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin runs a one-time Job that clones the specified repository into the configured volume and path.

---

## Prerequisites

- A shared persistent volume provisioned in your project
- The Git repository must be reachable from the cluster (public repo, or a private repo with credentials baked into the URL or SSH config)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"Git Loader"**
3. Click **Install**
4. Fill in the configuration fields below
5. Click **Confirm** to deploy

---

## Configuration

### Install-Time Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `install_volume` | shared-volume | **Yes** | — | Shared persistent volume to clone the repository into |
| `url` | string | **Yes** | — | Git repository URL (e.g. `https://github.com/org/repo.git`) |
| `ref` | string | **Yes** | — | Git reference to checkout — branch name, tag, or commit SHA |
| `destination` | string | **Yes** | — | Directory path within the volume where the repo will be cloned |

---

## Notes

- For private repositories, embed credentials in the URL (e.g. `https://user:token@github.com/org/repo.git`) or ensure SSH keys are available in the cluster
- This plugin clones once at install time; it does not track changes or pull updates — reinstall to refresh the clone
- The `destination` path must not already exist or must be an empty directory; an existing non-empty directory will cause the clone to fail
