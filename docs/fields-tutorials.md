# Tutorials

This guide provides hands-on tutorials for creating Terra plugins using different field approaches. Each tutorial includes complete, copy-paste ready examples.

## Tutorial 1: Simple Application Installation

This tutorial shows how to create a plugin for direct application installation using terra.yaml fields.

### Step 1: Create terra.yaml with String Fields

```yaml
# my-app/terra.yaml
resource_id: my-app
name: My Application
icon: https://example.com/icon.png
description: A simple application installation plugin
category: Software Development
tags:
  - application
  - development
fields:
  - name: version
    description: Version of application to install
    required: true
    default: "latest"
  - name: destination
    description: Installation directory
    required: true
    default: "/opt/my-app"
  - name: config_enabled
    description: Enable configuration management
    required: false
    type: boolean
    default: true
```

### Step 2: Create values.yaml with Default Values

```yaml
# my-app/values.yaml
# configuration
version: latest
destination: /opt/my-app
config_enabled: true
```

### Step 3: Create Helm Template

```yaml
# my-app/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  app-version: {{ .Values.version | quote }}
  install-path: {{ .Values.destination | quote }}
  {{ if .Values.config_enabled }}
  config-enabled: "true"
  {{ else }}
  config-enabled: "false"
  {{ end }}

# my-app/templates/install-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-install
spec:
  template:
    spec:
      containers:
        - name: installer
          image: my-app/installer:{{ .Values.version }}
          env:
            - name: DESTINATION
              value: {{ .Values.destination | quote }}
            - name: CONFIG_ENABLED
              value: {{ .Values.config_enabled | quote }}
      restartPolicy: Never
```

### Step 4: Test the Plugin

1. Install the plugin and verify:
   - String fields appear as text inputs in the Terra UI
   - Boolean field appears as a toggle switch
   - Default values are properly populated
2. Test with different field values
3. Verify template rendering works correctly
4. Check that the job runs with injected values

---

## Tutorial 2: Replication Template Creation

This tutorial shows how to create a plugin that becomes a workload template using metadata.yaml for template fields.

### Step 1: Create terra.yaml for Template Plugin

```yaml
# my-template/terra.yaml
resource_id: my-template
name: My Application Template
icon: https://example.com/template-icon.png
description: Template for creating customizable application workloads
category: Workload Templates
tags:
  - template
  - workload
fields: []
```

### Step 2: Create metadata.yaml with String Fields

```yaml
# my-template/templates/metadata.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-terra-metadata
data:
  chart: "{{ .Release.Name }}-scripts-configmap"
  description: "Customizable application workload template"
  fields: |
    - name: registry
      description: Registry to pull the application image from
      type: string
      required: true
      default: "docker.io"
    - name: repo
      description: Repository name for the application image
      type: string
      required: true
      default: "mycompany/myapp"
    - name: tag
      description: Image tag to deploy
      type: string
      required: true
      default: "latest"
    - name: replicas
      description: Number of replica instances
      type: int
      required: true
      default: 1
    - name: enable_monitoring
      description: Enable application monitoring
      type: boolean
      required: false
      default: true
```

### Step 3: Create Chart values.yaml

```yaml
# my-template/scripts/chart/values.yaml
name: my-app-template
user:
repo:              # ← Receives from metadata.yaml repo field
tag:               # ← Receives from metadata.yaml tag field
registry:          # ← Receives from metadata.yaml registry field
group:
cpu: "1"
memory: "1Gi"
replicas: 1        # ← Receives from metadata.yaml replicas field
enable_monitoring: true  # ← Receives from metadata.yaml enable_monitoring field
```

### Step 4: Create Helm Template

```yaml
# my-template/scripts/chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.name }}
    spec:
      containers:
        - name: my-app
          image: "{{ .Values.registry }}/{{ .Values.repo }}:{{ .Values.tag }}"
          ports:
            - containerPort: 8080
          {{ if .Values.enable_monitoring }}
          env:
            - name: MONITORING_ENABLED
              value: "true"
          {{ end }}
```

### Step 5: Test the Template

1. Install the plugin to create the template
2. Use the template to create workloads:
   - Verify all fields appear correctly in the Terra UI
   - Test with different field values
   - Check that integer field validates properly
   - Confirm boolean field works as toggle
3. Verify workload creation with different configurations
4. Check that chart receives and uses injected values correctly

---

## Tutorial 3: Complex Workload Template with Volumes

This tutorial shows advanced template creation with shared and exclusive volumes for complex applications.

### Step 1: Create terra.yaml for Complex Template

```yaml
# complex-template/terra.yaml
resource_id: complex-template
name: Complex Application Template
icon: https://example.com/complex-icon.png
description: Template for applications requiring multiple volumes and configurations
category: Workload Templates
tags:
  - template
  - complex
  - database
fields: []
```

### Step 2: Create metadata.yaml with Complex Fields

```yaml
# complex-template/templates/metadata.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-terra-metadata
data:
  chart: "{{ .Release.Name }}-scripts-configmap"
  description: "Complex application template with database storage"
  fields: |
    - name: registry
      description: Registry to pull images from
      type: string
      required: true
      default: "docker.io"
    - name: app_repo
      description: Application image repository
      type: string
      required: true
      default: "mycompany/app"
    - name: app_tag
      description: Application image tag
      type: string
      required: true
      default: "latest"
    - name: database_type
      description: Database type to use
      type: select
      required: true
      default: "postgresql"
      options:
        - postgresql
        - mysql
        - mongodb
    - name: install_volume
      description: Volume for application installation
      type: shared-volume
      required: true
    - name: database_volume
      description: Volume for database storage
      type: exclusive-volume
      required: true
```

### Step 3: Create Chart values.yaml

```yaml
# complex-template/scripts/chart/values.yaml
name: complex-app-template
user:
app_repo:            # ← From metadata.yaml
app_tag:             # ← From metadata.yaml
registry:            # ← From metadata.yaml
group:
cpu: "2"
memory: "4Gi"
database_type: postgresql  # ← From metadata.yaml

install_volume:       # ← From metadata.yaml shared-volume
  name: ""
  sub_path: ""
  container_path: ""

database_volume:      # ← From metadata.yaml exclusive-volume
  name: ""
```

### Step 4: Create Complex Helm Templates

```yaml
# complex-template/scripts/chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Values.name }}-app
  template:
    metadata:
      labels:
        app: {{ .Values.name }}-app
    spec:
      containers:
        - name: app
          image: "{{ .Values.registry }}/{{ .Values.app_repo }}:{{ .Values.app_tag }}"
          volumeMounts:
            - name: install-volume
              subPath: {{ .Values.install_volume.sub_path | quote }}
              mountPath: {{ .Values.install_volume.container_path | quote }}
      volumes:
        - name: install-volume
          persistentVolumeClaim:
            claimName: {{ .Values.install_volume.name | quote }}

# complex-template/scripts/chart/templates/database.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Values.name }}-{{ .Values.database_type }}
spec:
  replicas: 1
  serviceName: {{ .Values.name }}-{{ .Values.database_type }}
  volumeClaimTemplates:
    - metadata:
        name: database-volume
      spec:
        accessModes: ["ReadWriteOnce"]
  template:
    spec:
      containers:
        - name: {{ .Values.database_type }}
          image: {{ .Values.database_type }}:13
          volumeMounts:
            - name: database-volume
              mountPath: /var/lib/{{ .Values.database_type }}
```

### Step 5: Test the Complex Template

1. Install the plugin to create the complex template
2. Verify volume selection fields work correctly:
   - Shared volume selector shows available shared volumes
   - Exclusive volume selector shows available exclusive volumes
3. Test database type selection:
   - Try different database types
   - Verify select dropdown works properly
4. Create workloads with different volume configurations
5. Verify proper volume mounting and database deployment

---

## Tutorial 4: List Fields for Dynamic Configuration

This tutorial shows how to use list fields to allow users to create dynamic configurations.

### Step 1: Create terra.yaml with List Fields

```yaml
# dynamic-app/terra.yaml
resource_id: dynamic-app
name: Dynamic Application
icon: https://example.com/dynamic-icon.png
description: Application with configurable ports and mounts
category: Workload Templates
tags:
  - dynamic
  - configuration
fields: []
```

### Step 2: Create metadata.yaml with List Fields

```yaml
# dynamic-app/templates/metadata.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-terra-metadata
data:
  chart: "{{ .Release.Name }}-scripts-configmap"
  description: "Application with dynamic ports and mounts"
  fields: |
    - name: registry
      description: Registry to pull images from
      type: string
      required: true
      default: "docker.io"
    - name: app_repo
      description: Application repository
      type: string
      required: true
      default: "mycompany/dynamic-app"
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
          description: Name of the volume mount
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

### Step 3: Create Chart values.yaml

```yaml
# dynamic-app/scripts/chart/values.yaml
name: dynamic-app-template
user:
app_repo:            # ← From metadata.yaml
registry:            # ← From metadata.yaml
group:
cpu: "1"
memory: "1Gi"

ports:               # ← List field from metadata.yaml
mounts:              # ← List field from metadata.yaml
```

### Step 4: Create Templates with List Iteration

```yaml
# dynamic-app/scripts/chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Values.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.name }}
    spec:
      containers:
        - name: app
          image: "{{ .Values.registry }}/{{ .Values.app_repo }}:latest"
          ports:
            {{ range .Values.ports }}
            - containerPort: {{ .container_port }}
              name: {{ .name }}
              protocol: {{ .protocol }}
            {{ end }}
          volumeMounts:
            {{ range .Values.mounts }}
            - name: {{ .name }}
              mountPath: {{ .mount_path }}
            {{ end }}

# dynamic-app/scripts/chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-service
spec:
  selector:
    app: {{ .Values.name }}
  ports:
    {{ range .Values.ports }}
    - port: {{ .service_port }}
      targetPort: {{ .container_port }}
      name: {{ .name }}
      protocol: {{ .protocol }}
    {{ end }}

# dynamic-app/scripts/chart/templates/pvc.yaml
{{ range .Values.mounts }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .name }}-{{ $.Release.Name }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .storage_size }}
{{ end }}
```

### Step 5: Test the List Fields

1. Install the plugin to create the dynamic template
2. Test adding multiple ports:
   - Add HTTP, HTTPS, and admin ports
   - Verify each port's configuration options
   - Check that different protocols can be selected
3. Test adding multiple mounts:
   - Add data, logs, and cache mounts
   - Verify storage size configuration
   - Check mount path validation
4. Create workload and verify:
   - Deployment has correct container ports
   - Service exposes the right ports
   - PVCs are created for each mount

---

## Tutorial 5: Select and Multi Fields

This tutorial demonstrates select and multi fields for option-based configuration.

### Step 1: Create terra.yaml for Option-Based Template

```yaml
# options-app/terra.yaml
resource_id: options-app
name: Options Application
icon: https://example.com/options-icon.png
description: Application with configurable feature selection
category: Workload Templates
tags:
  - options
  - features
fields: []
```

### Step 2: Create metadata.yaml with Select and Multi Fields

```yaml
# options-app/templates/metadata.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-terra-metadata
data:
  chart: "{{ .Release.Name }}-scripts-configmap"
  description: "Application with feature and theme selection"
  fields: |
    - name: registry
      description: Registry to pull images from
      type: string
      required: true
      default: "docker.io"
    - name: app_repo
      description: Application repository
      type: string
      required: true
      default: "mycompany/options-app"
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
    - name: features
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
    - name: cpu_limit
      description: CPU limit for the application
      type: select
      required: true
      default: "1"
      options:
        - "0.5"
        - "1"
        - "2"
        - "4"
```

### Step 3: Create Chart values.yaml

```yaml
# options-app/scripts/chart/values.yaml
name: options-app-template
user:
app_repo:            # ← From metadata.yaml
registry:            # ← From metadata.yaml
group:
cpu: "1"
memory: "1Gi"

log_level: info       # ← From metadata.yaml select field
theme: light         # ← From metadata.yaml select field
features:            # ← From metadata.yaml multi field
cpu_limit: "1"      # ← From metadata.yaml select field
```

### Step 4: Create Templates with Option Handling

```yaml
# options-app/scripts/chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Values.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.name }}
    spec:
      containers:
        - name: app
          image: "{{ .Values.registry }}/{{ .Values.app_repo }}:latest"
          env:
            - name: LOG_LEVEL
              value: {{ .Values.log_level | quote }}
            - name: UI_THEME
              value: {{ .Values.theme | quote }}
            - name: ENABLED_FEATURES
              value: {{ .Values.features | join "," | quote }}
          resources:
            limits:
              cpu: {{ .Values.cpu_limit | quote }}
              memory: "2Gi"
            requests:
              cpu: "500m"
              memory: "1Gi"

# options-app/scripts/chart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  app-config.yaml: |
    logging:
      level: {{ .Values.log_level }}
    ui:
      theme: {{ .Values.theme }}
    features:
      {{ range .Values.features }}
      - {{ . | quote }}
      {{ end }}
    resources:
      cpu_limit: {{ .Values.cpu_limit }}
```

### Step 5: Test the Select and Multi Fields

1. Install the plugin to create the options template
2. Test select fields:
   - Try different log levels
   - Test theme selection
   - Verify CPU limit options
3. Test multi field:
   - Select multiple features
   - Verify they can be checked/unchecked
   - Check default selections work
4. Create workload and verify:
   - Environment variables contain selected values
   - ConfigMap has proper feature list
   - Resource limits match selection
