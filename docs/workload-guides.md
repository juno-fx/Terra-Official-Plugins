# Guides

Complete, annotated examples of workload template plugins. Each example shows all plugin-author
annotations in context with inline comments explaining the purpose of each.

---

## Example 1 — `simple-app`: Basic Web Application

A standard web application workload. Demonstrates actions, connection details, and ingress
endpoint control.

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
            - containerPort: 8080
```

```yaml title="scripts/chart/templates/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.name }}
spec:
  selector:
    app: {{ .Values.name }}
  ports:
    - port: 8080
      targetPort: 8080
```

```yaml title="scripts/chart/templates/ingress.yaml"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}
  annotations:
    kubernetes.io/ingress.class: nginx
    # Required: authenticate requests through Hubble before allowing access.
    nginx.ingress.kubernetes.io/auth-url: "http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/"
    nginx.ingress.kubernetes.io/use-regex: "true"
    # Hide internal paths from the Hubble endpoint list.
    kuiper.juno-innovations.com/ingress-hide: "/healthz,/metrics"
    # Surface additional deep-link paths as clickable endpoints in Hubble.
    kuiper.juno-innovations.com/ingress-extras: "/app/index.html"
spec:
  rules:
    - host: {{ .Values.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.name }}
                port:
                  number: 8080
```

---

## Example 2 — `ec2-workstation`: EC2-backed Remote Desktop

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
