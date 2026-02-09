# Fields

## Terra Plugin Field Types

Terra plugins support **8 field types** that work for **both direct installation and workload templates**. The same field types are available in both approaches - only the definition method differs:

- **Direct Installation**: Fields defined in `terra.yaml`
- **Workload Templates**: Fields defined as YAML strings in `metadata.yaml`

### Field Definition Schema

| Property      | Type    | Description                                      | Required |
|---------------|---------|--------------------------------------------------|----------|
| `name`        | String  | Field identifier (maps to values.yaml key)       | ✅ Yes    |
| `description` | String  | User-friendly description shown in UI            | ✅ Yes    |
| `required`    | Boolean | Whether field is mandatory (defaults to `false`) | ❌ No     |
| `type`        | String  | Field type (defaults to `string`)                | ❌ No     |
| `default`     | Any     | Default value for the field                      | ❌ No     |
| `options`     | Array   | List of choices for select/multi types           | ❌ No     |
| `fields`      | Array   | Nested field definitions for `list` type         | ❌ No     |

---

## String Fields

**Purpose:** Simple text input fields for configuration values like names, URLs, paths, and other textual information.

**Default when:** No type is specified (string is the default field type)

**Use Cases:** Application names, versions, paths, URLs, configuration keys, descriptions

### terra.yaml Definition
```yaml
fields:
  - name: chart_version
    description: Version of the Velero chart to install
    required: true
    default: 11.1.1
    type: string
  - name: bucket
    description: Name of the S3 bucket to store backups in
    required: true
  - name: region
    description: S3 Region - check your provider's documentation
    required: false
```

### metadata.yaml String Definition
```yaml
# For workload templates, define as YAML string in ConfigMap
data:
  fields: |
    - name: registry
      description: Registry to pull the image from
      type: string
      required: true
      default: "quay.io"
    - name: repo
      description: Repository to pull the image from
      type: string
      required: true
      default: "jupyter/datascience-notebook"
```

### Resulting values.yaml Structure
```yaml
# Direct installation output
chart_version: 11.1.1
s3Url: "https://s3.us-east-2.amazonaws.com"
bucket: example-bucket
region: us-east-2

# Workload template output (from Helm chart)
registry: "quay.io"
repo: "jupyter/datascience-notebook"
```

### Helm Template Usage
```yaml
# templates/deployment.yaml
spec:
  containers:
    - name: application
      image: "{{ .Values.registry }}/{{ .Values.repo }}:{{ .Values.chart_version }}"
      env:
        - name: AWS_BUCKET
          value: {{ .Values.bucket | quote }}
        - name: AWS_REGION
          value: {{ .Values.region | quote }}
```

---

## Boolean Fields

**Purpose:** True/false toggles for feature enablement, configuration switches, and binary options.

**Default Value:** `false` if not specified

**Use Cases:** Feature flags, debug mode, monitoring enablement, GPU support

### terra.yaml Definition
```yaml
fields:
  - name: nested_virtualization
    description: Enable nested virtualization support for VMs
    default: false
    required: true
    type: boolean
  - name: gpu
    description: Enable GPU support for this workload
    required: true
    type: boolean
    default: false
```

### metadata.yaml String Definition
```yaml
data:
  fields: |
    - name: enable_monitoring
      description: Enable application monitoring
      type: boolean
      required: false
      default: true
    - name: debug_mode
      description: Enable debug logging
      type: boolean
      required: false
      default: false
```

### Resulting values.yaml Structure
```yaml
# Direct installation output
nested_virtualization: false
gpu: false

# Workload template output
enable_monitoring: true
debug_mode: false
```

### Helm Template Usage
```yaml
# templates/vm.yaml
spec:
  domain:
    features:
      {{ if .Values.nested_virtualization }}
      acpi:
        enabled: true
      {{ end }}

# templates/deployment.yaml  
spec:
  {{ if .Values.gpu }}
  nodeSelector:
    accelerator: nvidia-tesla-k80
  {{ end }}

  {{ if .Values.enable_monitoring }}
  env:
    - name: MONITORING_ENABLED
      value: "true"
  {{ end }}
```

---

## Integer Fields

**Purpose:** Numeric input fields for configuration values requiring whole numbers.

**Default Value:** No default (must be provided if required)

**Use Cases:** Port numbers, replica counts, resource limits, version numbers

### terra.yaml Definition
```yaml
fields:
  - name: lun
    description: Logical Unit Number of the iSCSI target
    required: true
    type: int
    default: 0
  - name: worker_count
    description: Number of worker processes to spawn
    required: true
    type: int
    default: 2
```

### metadata.yaml String Definition
```yaml
data:
  fields: |
    - name: replicas
      description: Number of replica instances
      type: int
      required: true
      default: 1
    - name: max_connections
      description: Maximum number of database connections
      type: int
      required: false
      default: 100
```

### Resulting values.yaml Structure
```yaml
# Direct installation output
iqn: iqn.2024-01.com.example:target1
lun: 0
portal: 192.168.1.100

# Workload template output
replicas: 3
max_connections: 150
```

### Helm Template Usage
```yaml
# templates/persistentvolume.yaml
spec:
  iscsi:
    targetPortal: {{ .Values.portal | quote }}
    iqn: {{ .Values.iqn | quote }}
    lun: {{ .Values.lun }}
    chapAuthDiscovery: false
    chapAuthSession: false

# templates/deployment.yaml
spec:
  replicas: {{ .Values.replicas }}
  template:
    spec:
      containers:
        - name: database
          env:
            - name: MAX_CONNECTIONS
              value: {{ .Values.max_connections | quote }}
```

---

## Select Fields

**Purpose:** Single selection from predefined options, ensuring users can only choose valid values.

**Requires:** `options` array with allowed choices

**Use Cases:** Version selection, type selection, configuration modes, environment choices

### terra.yaml Definition
```yaml
fields:
  - name: version
    description: Version of KubeVirt to install
    required: true
    default: v1.7.0
    type: select
    options:
      - v1.7.0
      - v1.6.0
      - v1.5.0
  - name: database_type
    description: Database type to use
    required: true
    type: select
    options:
      - postgresql
      - mysql
      - mongodb
    default: postgresql
```

### metadata.yaml String Definition
```yaml
data:
  fields: |
    - name: log_level
      description: Logging level for the application
      type: select
      required: true
      default: "info"
      options:
        - debug
        - info
        - warn
        - error
    - name: theme
      description: UI theme for the application
      type: select
      required: true
      default: "light"
      options:
        - light
        - dark
        - auto
```

### Resulting values.yaml Structure
```yaml
# Direct installation output
version: v1.7.0
database_type: postgresql

# Workload template output
log_level: info
theme: light
```

### Helm Template Usage
```yaml
# templates/subscription.yaml
spec:
  channel: stable
  name: kubevirt
  startingCSV: kubevirt.v{{ .Values.version | replace "v" "" }}

# templates/deployment.yaml
env:
  - name: LOG_LEVEL
    value: {{ .Values.log_level | quote }}
  - name: UI_THEME
    value: {{ .Values.theme | quote }}

# templates/configmap.yaml
data:
  database.yml: |
    type: {{ .Values.database_type }}
    host: localhost
```

---

## Multi Fields

**Purpose:** Multiple selection from predefined options, allowing users to choose any combination of valid choices.

**Requires:** `options` array with allowed choices

**Use Cases:** Feature selection, plugin selection, tag selection, capability selection

### terra.yaml Definition
```yaml
fields:
  - name: features
    description: Select features to enable
    required: true
    type: multi
    options:
      - monitoring
      - logging
      - backup
      - security
    default: ["monitoring", "security"]
  - name: selected_plugins
    description: Choose plugins to install
    required: false
    type: multi
    options:
      - analytics
      - search
      - caching
      - notifications
```

### metadata.yaml String Definition
```yaml
data:
  fields: |
    - name: enabled_features
      description: Features to enable in the application
      type: multi
      required: false
      default: ["monitoring", "metrics"]
      options:
        - monitoring
        - metrics
        - logging
        - tracing
        - profiling
    - name: allowed_regions
      description: AWS regions where this workload can run
      type: multi
      required: true
      options:
        - us-east-1
        - us-west-2
        - eu-west-1
        - ap-southeast-2
```

### Resulting values.yaml Structure
```yaml
# Direct installation output
features:
  - monitoring
  - security
selected_plugins:
  - analytics
  - caching

# Workload template output
enabled_features:
  - monitoring
  - metrics
  - profiling
allowed_regions:
  - us-east-1
  - eu-west-1
```

### Helm Template Usage
```yaml
# templates/deployment.yaml
spec:
  containers:
    - name: application
      env:
        {{ range .Values.enabled_features }}
        - name: {{ . | upper }}_ENABLED
          value: "true"
        {{ end }}

# templates/configmap.yaml
data:
  enabled-plugins: {{ .Values.selected_plugins | join "," | quote }}
  config.json: |
    {
      "features": {{ .Values.enabled_features | toJson }},
      "regions": {{ .Values.allowed_regions | toJson }}
    }
```

---

## Shared Volume Fields

**Purpose:** Storage volumes that can be shared across multiple workloads, ideal for application installations and shared data.

**Output Structure:** `{name, sub_path, container_path}` object with volume details

**Use Cases:** Application installations, shared data repositories, configuration storage

### terra.yaml Definition
```yaml
fields:
  - name: install_volume
    description: The name of the install volume
    required: true
    type: shared-volume
  - name: config_volume
    description: Volume for shared configuration files
    required: false
    type: shared-volume
```

### metadata.yaml String Definition
```yaml
data:
  fields: |
    - name: install_volume
      description: Volume for application installation
      type: shared-volume
      required: true
    - name: data_volume
      description: Volume for shared application data
      type: shared-volume
      required: false
```

### Resulting values.yaml Structure
```yaml
# Direct installation output
install_volume:
  name: apps-pv-claim
  sub_path: 
  container_path: /apps

# Workload template output
install_volume:
  name: shared-data-pv-claim
  sub_path: my-app
  container_path: /shared
data_volume:
  name: config-pv-claim
  sub_path: ""
  container_path: /etc/config
```

### Helm Template Usage
```yaml
# templates/deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: application
          volumeMounts:
            - name: install-volume
              subPath: {{ .Values.install_volume.sub_path | quote }}
              mountPath: {{ .Values.install_volume.container_path | quote }}
            {{ if .Values.data_volume }}
            - name: data-volume
              subPath: {{ .Values.data_volume.sub_path | quote }}
              mountPath: {{ .Values.data_volume.container_path | quote }}
            {{ end }}
      volumes:
        - name: install-volume
          persistentVolumeClaim:
            claimName: {{ .Values.install_volume.name | quote }}
        {{ if .Values.data_volume }}
        - name: data-volume
          persistentVolumeClaim:
            claimName: {{ .Values.data_volume.name | quote }}
        {{ end }}
```

---

## Exclusive Volume Fields

**Purpose:** Storage volumes that can only be used by a single workload, perfect for databases and exclusive data storage.

**Output Structure:** `{name}` object with just the PVC name

**Use Cases:** Database storage, application logs, exclusive data, cache storage

### terra.yaml Definition
```yaml
fields:
  - name: database_volume
    description: The name of the database volume
    required: true
    type: exclusive-volume
  - name: log_volume
    description: Volume for application logs
    required: false
    type: exclusive-volume
```

### metadata.yaml String Definition
```yaml
data:
  fields: |
    - name: database_volume
      description: Volume for database storage
      type: exclusive-volume
      required: true
    - name: cache_volume
      description: Volume for application cache
      type: exclusive-volume
      required: false
```

### Resulting values.yaml Structure
```yaml
# Direct installation output
database_volume:
  name: data-pv-claim

# Workload template output
database_volume:
  name: postgres-data-pv-claim
cache_volume:
  name: redis-cache-pv-claim
```

### Helm Template Usage
```yaml
# templates/statefulset.yaml
spec:
  volumeClaimTemplates:
    - metadata:
        name: database-volume
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 100Gi
    {{ if .Values.cache_volume }}
    - metadata:
        name: cache-volume
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ssd
        resources:
          requests:
            storage: 10Gi
    {{ end }}
  template:
    spec:
      containers:
        - name: database
          volumeMounts:
            - name: database-volume
              mountPath: /var/lib/postgresql
            {{ if .Values.cache_volume }}
            - name: cache-volume
              mountPath: /var/cache/redis
            {{ end }}
```

---

## List Fields

**Purpose:** Groups of fields that can be duplicated multiple times by users, enabling dynamic configuration arrays.

**Requires:** Nested `fields` array defining the structure of each list item

**Use Cases:** Port configurations, volume mounts, environment variables, configuration arrays

### terra.yaml Definition
```yaml
fields:
  - name: ports
    description: Ports to expose from the application
    required: false
    type: list
    fields:
      - name: name
        description: Name of the port
        required: true
        type: string
        default: http
      - name: container_port
        description: Port inside the container
        required: true
        type: int
        default: 8080
      - name: service_port
        description: Port to expose on the service
        required: true
        type: int
        default: 80
      - name: protocol
        description: Protocol for the port
        required: true
        type: select
        default: TCP
        options:
          - TCP
          - UDP
  - name: mounts
    description: Volume mounts to add to the application
    required: false
    type: list
    fields:
      - name: name
        description: Name of the volume
        required: true
        type: string
      - name: mount_path
        description: Path to mount the volume
        required: true
        type: string
        default: /data
      - name: storage_size
        description: Size of the volume
        required: true
        type: string
        default: 1Gi
```

### metadata.yaml String Definition
```yaml
data:
  fields: |
    - name: environment_variables
      description: Environment variables to set for the application
      required: false
      type: list
      fields:
        - name: key
          description: Environment variable name
          required: true
          type: string
        - name: value
          description: Environment variable value
          required: true
          type: string
    - name: config_files
      description: Configuration files to create
      required: false
      type: list
      fields:
        - name: path
          description: File path in the container
          required: true
          type: string
        - name: content
          description: File content
          required: true
          type: string
```

### Resulting values.yaml Structure
```yaml
# Direct installation output (empty by default, populated by user input)
ports:
  - name: http
    container_port: 8080
    service_port: 80
    protocol: TCP
  - name: https
    container_port: 8443
    service_port: 443
    protocol: TCP

mounts:
  - name: data
    mount_path: /data
    storage_size: 10Gi
  - name: logs
    mount_path: /var/log
    storage_size: 5Gi

# Workload template output
environment_variables:
  - key: DATABASE_URL
    value: postgresql://localhost:5432/mydb
  - key: REDIS_HOST
    value: redis://localhost:6379

config_files:
  - path: /etc/app/config.yaml
    content: |
      server:
        port: 8080
        host: 0.0.0.0
```

### Helm Template Usage
```yaml
# templates/deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: application
          ports:
            {{ range .Values.ports }}
            - containerPort: {{ .container_port }}
              name: {{ .name }}
              protocol: {{ .protocol }}
            {{ end }}
          env:
            {{ range .Values.environment_variables }}
            - name: {{ .key | quote }}
              value: {{ .value | quote }}
            {{ end }}
          volumeMounts:
            {{ range .Values.mounts }}
            - name: {{ .name }}-volume
              mountPath: {{ .mount_path }}
            {{ end }}

# templates/service.yaml
spec:
  ports:
    {{ range .Values.ports }}
    - port: {{ .service_port }}
      targetPort: {{ .container_port }}
      name: {{ .name }}
      protocol: {{ .protocol }}
    {{ end }}

# templates/configmap.yaml
data:
  {{ range .Values.config_files }}
  {{ .path | quote }}: |
    {{ .content | indent 4 }}
  {{ end }}

# templates/pvc.yaml
{{ range .Values.mounts }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .name }}-volume-{{ $.Release.Name }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .storage_size }}
{{ end }}
```
