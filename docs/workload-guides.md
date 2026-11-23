# Guides

Complete, annotated examples of workload template plugins. Each example shows all plugin-author
annotations in context with inline comments explaining the purpose of each.

---

## Example 1: Basic Web Application

A standard web application workload. Demonstrates actions, connection details, ingress
endpoint control, and the nginx sidecar that enforces the Hubble login.

```yaml title="scripts/chart/templates/workload.yaml"
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Values.name }}
  annotations:
    # Declare the workload category for Hubble — shown on the running workload in the Hubble UI.
    # This value can be any string. It must match the value in templates/metadata.yaml:
    #   - metadata.yaml copy → read by Genesis to categorize the template in the catalog
    #   - workload.yaml copy → read by Hubble to label the active running workload
    juno-innovations.com/workload: "Application"
    # Whitelist which actions users can trigger on this StatefulSet via the Kuiper API.
    kuiper.juno-innovations.com/actions: "restart"
    # Expose static connection details in the Hubble UI alongside this workload's endpoints.
    kuiper.juno-innovations.com/connection: "username={{ .Values.user }},port=8080"
  labels:
    kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"
spec:
  selector:
    matchLabels:
      kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"
  template:
    metadata:
      labels:
        kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"
    spec:
      containers:
        # nginx sidecar — the only container reachable from outside the pod.
        # Enforces the Hubble login, then proxies to the app on 127.0.0.1.
        - name: nginx
          image: "{{ .Values.nginx_registry }}/{{ .Values.nginx_repo }}:{{ .Values.nginx_tag }}"
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: nginx
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
        - name: app
          image: "{{ .Values.registry }}/{{ .Values.repo }}:{{ .Values.tag }}"
          ports:
            # The app's own port. Not exposed by the Service or the NetworkPolicy.
            - containerPort: 3000
      volumes:
        - name: nginx
          configMap:
            name: "{{ .Values.name }}-nginx"
```

```nginx title="scripts/chart/files/nginx/nginx.conf"
events {}
http {
  server {
    listen 8080;
    listen [::]:8080;

    # Redirect the slashless path so relative assets resolve.
    # absolute_redirect off keeps the sidecar's http://...:8080 out of the Location header.
    location = /{{ .Release.Namespace }}/simple-app/{{ .Values.name }} {
      absolute_redirect off;
      return 301 $uri/;
    }

    location /{{ .Release.Namespace }}/simple-app/{{ .Values.name }}/ {
      # Required: authenticate requests through Hubble before allowing access.
      auth_request /auth;
      proxy_pass http://127.0.0.1:3000;
      proxy_http_version 1.1;
      # Websocket upgrade (covers the socket.io path below this prefix).
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      # Keep idle websockets open — this replaces the old proxy-read-timeout ingress annotation.
      proxy_read_timeout 3600s;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      # $scheme inside the sidecar is always http; pass the controller's scheme through.
      proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
    }

    location = /auth {
      internal;
      proxy_pass http://hubble.{{ .Release.Namespace }}.svc.cluster.local:3000/api/auth-workstation/{{ .Values.name }}/;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
      proxy_set_header X-Original-URI $request_uri;
    }
  }
}
```

```yaml title="scripts/chart/templates/nginx.yaml"
# Renders files/nginx/nginx.conf (with Helm values) into the ConfigMap the sidecar mounts.
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ .Values.name }}-nginx"
data:
  nginx.conf: |
{{ tpl (.Files.Get "files/nginx/nginx.conf") . | indent 4 }}
```

```yaml title="scripts/chart/templates/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.name }}
spec:
  selector:
    kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"
  ports:
    # The sidecar port — never the app port, or requests would skip the login.
    - port: 8080
      targetPort: 8080
```

```yaml title="scripts/chart/templates/ingress.yaml"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}
  # No nginx.ingress.kubernetes.io/* annotations — auth and timeouts live in the sidecar,
  # so this Ingress works with any controller.
  annotations:
    # Hide internal paths from the Hubble endpoint list.
    # Matched by exact string against the rendered path — must be the full path, not a bare sub-path.
    kuiper.juno-innovations.com/ingress-hide: "/{{ .Release.Namespace }}/simple-app/{{ .Values.name }}/socket.io"
    # Surface additional deep-link paths as clickable endpoints in Hubble.
    # Matched by prefix against an existing path; the remainder is appended.
    kuiper.juno-innovations.com/ingress-extras: "/{{ .Release.Namespace }}/simple-app/{{ .Values.name }}/app/index.html"
spec:
  # Kuiper >= 4.8.0 overwrites this with the launching namespace's IngressClass.
  ingressClassName: nginx
  rules:
    - host: {{ .Values.host }}
      http:
        # Paths start with the namespace so environments sharing a hostname cannot collide.
        # See "Ingress Path Convention" in AGENTS.md.
        paths:
          - path: "/{{ .Release.Namespace }}/simple-app/{{ .Values.name }}/"
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.name }}
                port:
                  number: 8080
          - path: "/{{ .Release.Namespace }}/simple-app/{{ .Values.name }}/socket.io"
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.name }}
                port:
                  number: 8080
```

```yaml title="scripts/chart/templates/network-policy.yaml"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Values.name }}-network-policy
spec:
  podSelector:
    matchLabels:
      kuiper.juno-innovations.com/kuiper-instance: "{{ .Values.name }}"
  policyTypes:
    - Ingress
  # Only the sidecar port is reachable. No `from` — the sidecar does its own auth,
  # so traffic is accepted from whichever ingress controller the cluster runs.
  ingress:
    - ports:
        - protocol: TCP
          port: 8080
```

!!! warning "The container must know its own path"

    The Ingress never rewrites the path, so the sidecar receives `/<namespace>/simple-app/<name>/…`
    in full, and so does the app unless the sidecar's `nginx.conf` rewrites it. Whatever tells the
    app its base path (`PREFIX`, `--baseURL`, `ROOT_URL`, the sidecar `location`) has to carry the
    same value, or the request routes correctly and then 404s inside the pod.

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

    # Use the private address instead of the public DNS name.
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
