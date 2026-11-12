{{/* Host namespace the vCluster is installed into — the user's project namespace */}}
{{- define "vcluster-juno.namespace" -}}
{{ .Release.Namespace }}
{{- end -}}

{{/* Ownership label stamped on every resource this plugin creates */}}
{{- define "vcluster-juno.labels" -}}
kuiper.juno-innovations.com/kuiper-instance: {{ .Release.Name | quote }}
{{- end -}}

{{/* K8s version normalized to a v-prefixed tag — the ghcr.io/loft-sh/kubernetes image requires it */}}
{{- define "vcluster-juno.k8sVersion" -}}
v{{ .Values.k8s_version | trimPrefix "v" }}
{{- end -}}

{{/* In-cluster server URL for the vCluster API (must be covered by the cert SANs) */}}
{{- define "vcluster-juno.server" -}}
https://{{ .Release.Name }}.{{ include "vcluster-juno.namespace" . }}.svc
{{- end -}}

{{/* Genesis env block for the selected auth type */}}
{{- define "vcluster-juno.authEnv" -}}
{{- if eq .Values.auth_type "basic" }}
BASIC_AUTH_EMAIL: {{ .Values.basic_auth_email | quote }}
BASIC_AUTH_PASSWORD: {{ .Values.basic_auth_password | quote }}
{{- else if eq .Values.auth_type "google" }}
GOOGLE_CLIENT_ID: {{ .Values.google_client_id | quote }}
GOOGLE_CLIENT_SECRET: {{ .Values.google_client_secret | quote }}
{{- else if eq .Values.auth_type "cognito" }}
COGNITO_CLIENT_ID: {{ .Values.cognito_client_id | quote }}
COGNITO_CLIENT_SECRET: {{ .Values.cognito_client_secret | quote }}
COGNITO_ISSUER: {{ .Values.cognito_issuer | quote }}
{{- else if eq .Values.auth_type "ldap" }}
LDAP_URI: {{ .Values.ldap_uri | quote }}
LDAP_BIND_DN: {{ .Values.ldap_bind_dn | quote }}
LDAP_BIND_PASSWORD: {{ .Values.ldap_bind_password | quote }}
LDAP_SEARCH_BASE: {{ .Values.ldap_search_base | quote }}
{{- end }}
{{- end -}}
