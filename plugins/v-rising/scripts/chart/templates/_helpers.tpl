{{/*
  Deterministic nodePort pair derivation — ported from the conan-exiles plugin
  in aldmbmtl/Terra-Games.

  The V Rising client queries the server at entered-port + 1, so the game and
  query nodePorts MUST be an adjacent pair (N / N+1). Kubernetes would otherwise
  allocate two random, unrelated nodePorts and the client's query would miss.

  The pair is derived from the instance name rather than assigned, so it is
  stable across ArgoCD syncs and Kuiper re-renders: the sha256 hex's decimal
  digit-runs are summed and folded into the nodePort range. mod 2767 keeps the
  game port in 30000..32766 so +1 never overflows the 32767 ceiling.

  No user override — always auto-derived. If the apply is rejected because the
  ports are already in use, rename the instance to re-derive a different pair.
*/}}
{{- define "v-rising.autoNodePort" -}}
{{- $sum := 0 -}}
{{- range $i, $run := regexFindAll "[0-9]+" (sha256sum .Release.Name) -1 -}}
{{- /* mod inside the loop, not just at the end: keeps $sum bounded so a name
       whose digit-runs sum past int64 cannot wrap negative and derive a port
       below 30000. Modular arithmetic distributes over addition, so this yields
       an identical port to the plain sum for every non-overflowing name. */ -}}
{{- $sum = mod (add $sum (int $run)) 2767 -}}
{{- end -}}
{{- add 30000 (mod $sum 2767) -}}
{{- end -}}

{{/*
  Effective game / query ports.

  These resolve to the SAME number inside the container and outside it. Under
  NodePort the server must bind the derived nodePort itself — kube-proxy DNATs
  nodeIP:31282 to the pod, but V Rising answers and advertises on the port it
  believes it owns, so a container bound to 9876 leaves the client waiting on a
  reply that never comes (connection timeout).

  Binding the nodePort directly also makes the advertised port the reachable
  one, which is what lets the server browser work at all.

  For LoadBalancer / ClusterIP there is no port translation, so the plain
  container ports are already correct.
*/}}
{{- define "v-rising.gamePort" -}}
{{- if eq .Values.service_type "NodePort" -}}
{{- include "v-rising.autoNodePort" . -}}
{{- else -}}
{{- .Values.game_port -}}
{{- end -}}
{{- end -}}

{{- define "v-rising.queryPort" -}}
{{- if eq .Values.service_type "NodePort" -}}
{{- add (include "v-rising.autoNodePort" . | int) 1 -}}
{{- else -}}
{{- .Values.query_port -}}
{{- end -}}
{{- end -}}
