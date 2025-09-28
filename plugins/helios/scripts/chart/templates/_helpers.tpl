{{/* This is only needed until 1.X.Y is sunset to provide compatibility */}}
{{- define "juno.proxyNamespace" -}}
  {{- $proxyNamespace := .Values.proxy_namespace | default "" }}
  {{- if not $proxyNamespace }}
    {{- if .Values._juno_gateway_api }}
      {{- $proxyNamespace = "traefik" }}
    {{- else }}
      {{- $proxyNamespace = "ingress-nginx" }}
    {{- end }}
  {{- end }}
  {{- $proxyNamespace }}
{{- end }}
