# Theme Enforcer XFCE

![XFCE](https://upload.wikimedia.org/wikipedia/commons/5/5b/Xfce_logo.svg)

**Category:** Desktop Plugin
**Type:** Namespaced Plugin
**Tags:** `xfce` · `theme` · `desktop` · `customization`

---

## Overview

The Theme Enforcer XFCE plugin applies and enforces consistent theme settings across XFCE desktop environments running in your project's workstations. It ensures that all users see a uniform desktop appearance — including window decorations, icon themes, and GTK styling — regardless of individual user configuration changes. This is useful for studios and organizations that want a branded or standardized desktop experience across all workstations.

---

## Plugin Type

**Namespaced Plugin** — Installed into your project namespace. This plugin installs theme enforcement scripts that are applied to XFCE workstations running in the same project.

---

## Prerequisites

- Workstations running an **XFCE** desktop environment (e.g. **Helios** with an XFCE-based image)

---

## Installation

1. Open **Terra** and navigate to the **Plugin Marketplace**
2. Search for **"theme-enforcer-xfce"**
3. Click **Install**
4. Click **Confirm** to deploy (no configuration required)

Once installed, the theme enforcement scripts will be applied to XFCE workstations in the project at startup.

---

## Configuration

### Install-Time Fields

No install-time configuration is required for this plugin.

---

## Notes

- This plugin only affects workstations using an **XFCE** desktop environment — it has no effect on other desktop environments (GNOME, KDE, etc.)
- Theme settings are enforced at workstation startup; users may temporarily change settings within a session, but changes will be reset on next workstation launch
