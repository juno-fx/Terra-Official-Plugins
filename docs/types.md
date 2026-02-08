# Plugin Types

## Introduction to Terra Plugin Types

Terra uses a sophisticated two-tier field system that enables both direct application installation and workload template creation:

### Direct Installation vs Workload Templates

Terra plugins support two distinct approaches for application deployment:

**Direct Installation (terra.yaml → values.yaml)**
- Fields are defined in `terra.yaml`
- Terra injects field values directly into the plugin's `values.yaml`
- Used for one-time application installations
- Simpler workflow for basic deployments

**Workload Templates (terra.yaml → metadata.yaml → Helm Chart)**
- Initial plugin defined in `terra.yaml` (often with empty fields array)
- After installation, plugin becomes a workload template
- Template fields are defined as strings in `metadata.yaml` ConfigMaps
- Terra injects field values into Helm chart `values.yaml`
- Used for creating reusable, customizable workloads
- Supports complex configurations and replication

### Architecture Overview

```
┌─────────────────┐
│   terra.yaml    │
│                 │
│                 │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│  Plugin Install │
│                 │
│                 │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ metadata.yaml   │  ← Template Fields (for Workload Templates)
│ (String Fields) │
│                 │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│   Helm Chart    │───▶ Workload
│                 │
│                 │
└─────────────────┘
```

### Important Note
**All field types work for both approaches** - the same 8 field types are available whether you're doing direct installation or creating workload templates. The only difference is how fields are defined:
- Direct Installation: Fields defined directly in `terra.yaml`
- Workload Templates: Fields defined as YAML strings in `metadata.yaml`

### When to Use Each Approach

**Use terra.yaml fields for:**
- Direct application installation
- Simple configuration needs
- Quick plugin deployment
- One-time software installs

**Use metadata.yaml fields for:**
- Creating workload templates
- Replication and scaling
- Complex application configurations
- Multi-environment deployments
