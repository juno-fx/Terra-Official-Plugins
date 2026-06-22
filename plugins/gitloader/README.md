# Git Loader

<img src="https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png" alt="Git Loader" width="80" />

**Category:** Utility
**Type:** Software Installer
**Tags:** `git` · `loader` · `repository` · `clone`

---

## Overview

The Git Loader plugin clones a Git repository from any Git source into a shared persistent volume in your project. It is useful for seeding shared volumes with configuration files, project assets, scripts, or source code — making them immediately available to workstations without manual setup. Simply point it at a repository URL and branch, and it will clone the specified ref to the target path.

---

## How It Works

**Software Installer** — When added to a project, Terra clones the specified Git repository into the shared volume and path you configure. This runs once at install time; the files are then available to all workstations in the project that mount the volume.

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

| Field | Details |
|-------|---------|
| `install_volume` | **shared-volume** · Required<br>Shared persistent volume to clone the repository into |
| `url` | **string** · Required<br>Git repository URL (e.g. `https://github.com/org/repo.git`) |
| `ref` | **string** · Required<br>Git reference to checkout — branch name, tag, or commit SHA |
| `destination` | **string** · Required<br>Directory path within the volume where the repo will be cloned |

---

## Notes

- For private repositories, embed credentials in the URL (e.g. `https://user:token@github.com/org/repo.git`) or ensure SSH keys are available in the cluster
- This plugin clones once at install time; it does not track changes or pull updates — reinstall to refresh the clone
- The `destination` path must not already exist or must be an empty directory; an existing non-empty directory will cause the clone to fail
