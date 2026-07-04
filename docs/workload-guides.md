# Guides

Complete, annotated examples of workload template plugins. Each example shows all plugin-author
annotations in context with inline comments explaining the purpose of each.

---

## Example 1: Basic Web Application

A standard web application workload with nginx sidecar authentication. Demonstrates actions,
connection details, ingress endpoint control, and the sidecar auth pattern.

```yaml title="scripts/chart/templates/workstation.yaml"
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Values.name }}
  annotations:
    # Declare the workload category for Hubble — shown on the running workload in the Hubble UI.
    # This value can be any string. It must match the value in templates/metadata.yaml:
    #   - metadata.yaml copy → read by Genesis to categorize the template in the catalog
    #   - workstation.yaml copy → read by Hubble to label the active running workload
    juno-innovations.com/workload: "Application"
    # Whitelist which actions users can trigger on this StatefulSet via the Kuiper API.
    kuiper.juno-innovations.com/actions: "restart"
    # Expose static connection details in the Hubble UI alongside this workload's endpoints.
    kuiper.juno-innovations.com/connection: "username={{ .Values.user }},port=8080"
spec:
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
          image: "{{ .Values.registry }}/{{ .Values.repo }}:{{ .Values.tag }}"
          ports:
            - containerPort: 8081
              name: app
        - name: nginx
          image: "{{ .Values.nginx_registry }}/{{ .Values.nginx_repo }}:{{ .Values.nginx_tag }}"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
              name: http
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
      volumes:
        - name: nginx-config
          configMap:
            name: {{ .Release.Name }}-nginx
```

```yaml title="scripts/chart/templates/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  selector:
    app: {{ .Values.name }}
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
      name: http
```

```yaml title="scripts/chart/templates/ingress.yaml"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}-ingress
  annotations:
    # Hide internal paths from the Hubble endpoint list.
    kuiper.juno-innovations.com/ingress-hide: "/socket.io"
    # Surface additional deep-link paths as clickable endpoints in Hubble.
    kuiper.juno-innovations.com/ingress-extras: "/app/index.html"
spec:
  {{- if .Values.ingressClassName }}
  ingressClassName: {{ .Values.ingressClassName }}
  {{- end }}
  rules:
    - host: {{ .Values.host }}
      http:
        paths:
          - path: "/plugin/{{ .Values.name }}/"
            pathType: Prefix
            backend:
              service:
                name: {{ .Release.Name }}
                port:
                  number: 8080
```

```yaml title="scripts/chart/templates/nginx-configmap.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-nginx
  labels:
    kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"
data:
  default.conf: |
{{ tpl (.Files.Get "files/nginx/default.conf") . | indent 4 }}
```

```nginx title="scripts/chart/files/nginx/default.conf"
server {
    listen 8080;
    server_name _;

    location /plugin/{{ .Values.name }}/ {
        auth_request /auth;
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location = /auth {
        internal;
        proxy_pass http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header Upgrade "";
        proxy_set_header Connection "";
    }
}
```

---

## Example 2: EC2-backed Remote Desktop

A workload backed by a Crossplane-managed EC2 instance. Demonstrates EC2-specific annotations
and the `adopt` pattern for resources Kuiper creates after launch.

```yaml title="scripts/chart/templates/ec2-instance.yaml"
apiVersion: ec2.aws.crossplane.io/v1alpha1
kind: Instance
metadata:
  name: {{ .Values.name }}-ec2
  annotations:
    # Tell Kuiper to auto-create an ExternalName Service exposing these ports
    # once EC2 DNS is available. The service name will be deterministic:
    # {{ .Values.name }}-ec2-svc
    kuiper.juno-innovations.com/expose: "22,3389"

    # Once EC2 DNS is ready, instruct Kuiper to compute and write the
    # connection annotation on this object so Hubble can display it.
    kuiper.juno-innovations.com/aws-remote-connection: "true"

    # Use the private DNS name instead of the public one.
    # Remove this line if the instance should be reached via public DNS.
    kuiper.juno-innovations.com/use-private-dns: "true"

    # Adopt the ExternalName Service that Kuiper will create post-launch.
    # This makes it an owned resource of the workload so it is cleaned up
    # on shutdown. The service name is deterministic — Kuiper names it
    # {{ .Values.name }}-ec2-svc when it processes the expose annotation.
    kuiper.juno-innovations.com/adopt-{{ .Values.name }}-ec2-svc: "Service"
spec:
  forProvider:
    region: {{ .Values.region }}
    instanceType: {{ .Values.instance_type }}
    ami: {{ .Values.ami }}
```
