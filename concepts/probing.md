# Probing — Requirements Discovery for New Plugins & New Features

**When to use:** creating a new plugin, OR adding a feature/field to an existing plugin.
Before writing chart code, probe what the workload actually needs — then wire it from the
concepts.

## Why probe

The template is a deliberately **generic baseline** — no env vars, no probes, no mounts, no
GPU, no sidecars. Features are added per workload, not pre-baked. The author often does not
know which features their workload needs, so the agent suggests, and the author confirms.

## Rule 1 — ASK: the probe checklist

Walk these before touching `scripts/chart/`:

| Probe | Ask | Maps to |
|-------|-----|---------|
| Purpose | What does the workload do? What kind of app is it (GUI, server, IDE, agent)? | `concepts/runtime.md` |
| Interface | Web UI, HTTP API, desktop, headless? | `concepts/ingress.md` |
| Compute | GPU needed (ML, rendering, CUDA)? | `concepts/gpu.md` |
| Persistence | Stateful data, caches, uploads? | `concepts/storage.md` |
| Ingress protection | Protected (platform auth) or public? | `concepts/ingress.md` |
| Access | Non-HTTP traffic (game, SSH, LDAP, raw protocol) or direct node port needed? | `concepts/service-exposure.md` |
| Runtime quirks | Browser/electron/chromium, slow boot, health endpoint? | `concepts/runtime.md`, `concepts/storage.md` |
| Env | Custom env vars the image supports? Built to read platform vars (PREFIX, USER, HOME, UID/GID, JUNO_*)? | `concepts/env.md` |
| Image source | Private registry needing credentials? | `concepts/runtime.md` |
| Node targeting | Must land on specific nodes (GPU, dedicated pools)? | `concepts/affinity.md` |
| Compute | OS-level VM (Windows, legacy OS, full kernel boot)? | `concepts/vm.md` |
| Compute | Cloud instance (EC2, managed VM)? | `concepts/crossplane.md` |
| Interface | Fronts existing externally-managed infrastructure (VDI broker, appliance, gateway)? | `concepts/connection-brokers.md` |

## Rule 2 — SUGGEST: propose what the author may not know

The author may not realize their workload needs a feature. When the workload's characteristics
imply one, propose it — don't wait to be asked:

| Workload characteristic | Suggest |
|-------------------------|---------|
| Chromium/Electron/browser-based app | `/dev/shm` memory-backed `emptyDir` mount (browsers fault without writable shared memory) |
| ML inference, LLM, rendering, CUDA | GPU field + `runtimeClassName: nvidia` (`concepts/gpu.md`) |
| Web UI / webhook / API service | Ingress + auth decision (`concepts/ingress.md`) |
| Persistent state, uploads, databases | Storage (`concepts/storage.md`) |
| App needs base-path awareness | `PREFIX` env matching the ingress path (`concepts/ingress.md`) |
| Slow cold start / health endpoint | startup/liveness/httpGet probes (`concepts/runtime.md`) |
| Private image registry | `pullSecret` wiring (`concepts/runtime.md`) |
| Image built to consume platform vars (linuxserver-style USER/HOME/UID/GID entrypoint, base-path-aware PREFIX) | Platform env var pass-through (`concepts/env.md`) |
| Windows/legacy OS, kernel-level isolation, GPU device passthrough | KubeVirt VM — `concepts/vm.md` |
| Cloud VM / managed instance backend | Crossplane — `concepts/crossplane.md` |
| External appliance / VDI broker / non-container backend | Connection broker — `concepts/connection-brokers.md` |
| Game server / raw TCP-UDP / non-HTTP protocol | NodePort/LoadBalancer Service — no ingress (`concepts/service-exposure.md`) |
| Client expects consecutive ports (pinger, mod listing, RDP family) | Deterministic adjacent nodePort range (`concepts/service-exposure.md`) |

**Never add silently.** Each suggestion is confirmed with the author before it lands in the
chart.

## Rule 3 — wire each confirmed need from its concept file

Every confirmed feature is implemented from the matching concept (they contain the values
keys, template snippets, and gotchas). Adding a field to `templates/metadata.yaml` **without**
the matching key in `scripts/chart/values.yaml` breaks Helm rendering at launch (Rule 3 in
AGENTS.md) — the field name and the values key must match exactly.

## Rule 4 — start from the template, add only what was confirmed

Unconfirmed features stay out. The template baseline stays intact; features arrive as small,
concept-backed additions. For existing plugins, the same probe applies before adding any
field or block — an existing workload may not need what a new one does.

Every confirmed feature must clear the quality bar in `concepts/best-practices.md` — probing
decides *what*, best practices decide *how well*.

## After probing

1. Confirm the feature set with the author
2. Add metadata.yaml fields + matching values.yaml keys
3. Wire workload.yaml (and service/ingress as needed) per the concept files
4. If `workload.yaml` ranges over `.Values.env`: fill `env_hints` in metadata.yaml and mirror
   in the README (`concepts/env.md`)
5. `make package <plugin>` if `scripts/` changed; `make verify`

## See also

- `concepts/` — the full how-to library; each probe row maps here
- AGENTS.md — "Plugin Authoring — Probe First" (condensed checklist)