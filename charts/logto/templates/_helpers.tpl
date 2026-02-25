{{/*
Common container spec for Logto (image, imagePullPolicy, securityContext, env, envFrom, resources, volumeMounts)
Usage: include "logto.commonContainerSpec" .
*/}}
{{- define "logto.commonContainerSpec" -}}
securityContext:
  {{- toYaml .Values.securityContext | nindent 12 }}
image: "{{ .Values.image.registry}}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
imagePullPolicy: {{ .Values.image.pullPolicy }}
env:
  - name: PORT
    value: {{ include "logto.coreServicePort" . | quote }}
  - name: ADMIN_PORT
    value: {{ include "logto.adminServicePort" . | quote }}

  {{- if .Values.dbUrl.valueFrom }}
  - name: DB_URL
    valueFrom:
      {{- toYaml .Values.dbUrl.valueFrom | nindent 6 }}
  {{- else if .Values.dbUrl.value }}
  - name: DB_URL
    value: {{ .Values.dbUrl.value | quote }}
  {{- end }}
  {{- if .Values.endpoint }}
  - name: ENDPOINT
    value: {{ .Values.endpoint | quote }}
  {{- end }}
  {{- if .Values.console.endpoint }}
  - name: ADMIN_ENDPOINT
    value: {{ .Values.console.endpoint | quote }}
  {{- end }}

  {{- if .Values.console.disableLocalhost }}
  - name: ADMIN_DISABLE_LOCALHOST
    value: "true"
  {{- end }}

  {{- if .Values.nodeEnv }}
  - name: NODE_ENV
    value: {{ .Values.nodeEnv | quote }}
  {{- end }}
  {{- if .Values.databaseStatementTimeout }}
  - name: DATABASE_STATEMENT_TIMEOUT
    value: {{ .Values.databaseStatementTimeout | quote }}
  {{- end }}
  {{- if .Values.httpsCertPath }}
  - name: HTTPS_CERT_PATH
    value: {{ .Values.httpsCertPath | quote }}
  {{- end }}
  {{- if .Values.httpsKeyPath }}
  - name: HTTPS_KEY_PATH
    value: {{ .Values.httpsKeyPath | quote }}
  {{- end }}
  {{- if .Values.trustProxyHeader }}
  - name: TRUST_PROXY_HEADER
    value: {{ .Values.trustProxyHeader | quote }}
  {{- end }}
  {{- if .Values.caseSensitiveUsername }}
  - name: CASE_SENSITIVE_USERNAME
    value: {{ .Values.caseSensitiveUsername | quote }}
  {{- end }}
  {{- if .Values.secretVaultKek }}
  - name: SECRET_VAULT_KEK
    value: {{ .Values.secretVaultKek | quote }}
  {{- end }}
envFrom:
  - secretRef:
      name: {{ include "logto.secretName" . }}
  - configMapRef:
      name: {{ include "logto.configMapName" . }}
resources:
  {{- toYaml .Values.resources | nindent 2 }}
{{- with .Values.volumeMounts }}
volumeMounts:
  {{- toYaml . | nindent 2 }}
{{- end }}
  {{- if .Values.emmbedded_tls.enabled }}
- name: emmbedded_tls
  mountPath: /etc/logto/tls
  readOnly: true
  {{- end }}
{{- end -}}
{{/*
Return the dict of all services (core/admin)
Usage: include "logto.serviceDict" .
*/}}
{{- define "logto.serviceDict" -}}
{{ dict "core" .Values.service "admin" .Values.console.service | toYaml }}
{{- end -}}
{{/*
Return the core service port for logto
*/}}
{{- define "logto.coreServicePort" -}}
{{ .Values.service.port }}
{{- end -}}
{{/*
Return the admin service port for logto
*/}}
{{- define "logto.adminServicePort" -}}
{{ .Values.console.service.port }}
{{- end -}}
{{/*
Return the admin service name for logto
*/}}
{{- define "logto.adminServiceName" -}}
{{ include "logto.fullname" . }}-{{ .Values.console.service.name }}
{{- end -}}
{{/*
Return the core service name for logto
*/}}
{{- define "logto.coreServiceName" -}}
{{ include "logto.fullname" . }}-{{ .Values.service.name }}
{{- end -}}
{{/*
Expand the name of the chart.
*/}}
{{- define "logto.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "logto.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "logto.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "logto.labels" -}}
helm.sh/chart: {{ include "logto.chart" . }}
{{ include "logto.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "logto.selectorLabels" -}}
app.kubernetes.io/name: {{ include "logto.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "logto.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "logto.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of secret
*/}}
{{- define "logto.secretName" -}}
{{- include "logto.fullname" . }}
{{- end }}

{{/*
*/}}
{{- define "logto.configMapName" -}}
{{- include "logto.fullname" . }}
{{- end }}
