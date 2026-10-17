# Storage — Persistence, Volumes, Mounts

**When to use:** the workload needs persistent data, extra mounts, or user-chosen storage —
PVs, PVCs, shared volumes, KubeVirt DataVolumes.

Storage has **two distinct paths** depending on plugin type. Pick the one that matches.

## Path A — Namespaced / cluster-level plugins (install-time)

Storage is chosen **when the plugin is installed** via `terra.yaml` field types. The user picks
a volume in the Terra UI; Terra provisions it; the chart mounts the selected claim.

```yaml
# terra.yaml — fields
- name: install_volume
  description: "The volume to store persisted data."
  required: true
  type: shared-volume   # or exclusive-volume
```

```yaml
# templates/resources.yaml — mount the chosen claim
volumeMounts:
  - name: data
    mountPath: "/data"
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: {{ .Values.install_volume.name }}
```

Reference: `plugins/ollama/terra.yaml` + `plugins/ollama/templates/wave-1/deployment.yaml`
(the claim mounts at `/root/.ollama`).

- `shared-volume` — multiple plugins may share the volume
- `exclusive-volume` — single plugin only

## Path B — Workload templates (launch-time, Kuiper-managed)

Storage is attached **when the workload launches** in the Genesis UI. Kuiper injects the
`volumeMounts` and `volumes` values; the chart just ranges them through:

```yaml
# scripts/chart/templates/workload.yaml
volumeMounts:
  - mountPath: /dev/shm
    name: shm
  {{- if .Values.volumeMounts }}
  {{- toYaml .Values.volumeMounts | nindent 12 }}
  {{- end }}
volumes:
  - name: shm
    emptyDir:
      medium: Memory
      sizeLimit: 1Gi
  {{- if .Values.volumes }}
  {{- toYaml .Values.volumes | nindent 8 }}
  {{- end }}
```

The `/dev/shm` memory-backed `emptyDir` is probe-added — browsers and Electron apps fault
without writable shared memory, so **suggest it** whenever the workload is Chromium-based
(`concepts/probing.md`, Rule 2):

### Letting users choose storage at launch

Add these field types to `templates/metadata.yaml`:

| Field type | What the user picks |
|------------|---------------------|
| `k8sStorageClass` | A StorageClass; value flows to `values.yaml` for the chart to use in PVC specs |
| `dataVolume` | A KubeVirt DataVolume (only DVs labeled `kuiper.juno-innovations.com/user-created-datavolume`) |

Used by boinc, claude-code, gitea, github-runner and others. Field `name` must match the
`values.yaml` key exactly (Rule 3).

### Kuiper-managed mount annotations — do not set

Kuiper writes these onto the PVCs it manages at launch:

- `kuiper.juno-innovations.com/container-path` — mount target inside the container
- `kuiper.juno-innovations.com/sub-path` — sub-directory within a PVC to mount
- `kuiper.juno-innovations.com/mount-access` — JSON array of Juno users/groups permitted to use the mount

Never set them in charts — Kuiper owns them for the mounts it creates.

## Gotchas

- **PVCs persist; pods don't.** The template uses a StatefulSet so stable pod identity and
  volume rebinding survive restarts — don't swap to a Deployment for storage-backed workloads
  without a reattachment story.
- A `shared-volume`/`exclusive-volume` install-time mount name must be `{{ .Values.<field>.name }}`
  — the field value carries the claim name, not a mount path.
- `dataVolume` is KubeVirt-only (Virtual Machine workloads); plain container workloads use
  `k8sStorageClass` + Kuiper-injected volumes.

## See also

- `concepts/runtime.md` — container-level runtime config
- `docs/plugin-fields.md` — full field type reference
- `docs/workload-configuration.md` — volumes/volumeMounts values