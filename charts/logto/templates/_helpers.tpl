{{/*
Common container spec for Logto (image, imagePullPolicy, securityContext, env, envFrom, resources, volumeMounts)
Usage: include "logto.commonContainerSpec" .
Allows passing dbUrl parameter, which takes precedence over .Values.dbUrl.
Usage: include "logto.commonContainerSpec" (dict "dbUrl" .dbUrl "context" .)
*/}}
{{- define "logto.commonContainerSpec" -}}
{{- $ctx := .context | default . -}}
{{- $dbUrl := .dbUrl | default $ctx.Values.dbUrl -}}
{{- $embeddedTls := .embeddedTls | default $ctx.Values.embeddedTls -}}
securityContext:
  {{- toYaml $ctx.Values.securityContext | nindent 2 }}
image: "{{ $ctx.Values.image.registry }}/{{ $ctx.Values.image.repository }}:{{ $ctx.Values.image.tag | default $ctx.Chart.AppVersion }}"
imagePullPolicy: {{ $ctx.Values.image.pullPolicy }}
env:
  - name: PORT
    value: {{ include "logto.coreServicePort" $ctx | quote }}
  - name: ADMIN_PORT
    value: {{ include "logto.adminServicePort" $ctx | quote }}

  {{- if $dbUrl.valueFrom }}
  - name: DB_URL
    valueFrom:
      {{- toYaml $dbUrl.valueFrom | nindent 6 }}
  {{- else if $dbUrl.value }}
  - name: DB_URL
    value: {{ $dbUrl.value | quote }}
  {{- end }}
  {{- if $ctx.Values.endpoint }}
  - name: ENDPOINT
    value: {{ $ctx.Values.endpoint | quote }}
  {{- end }}
  {{- if $ctx.Values.console.endpoint }}
  - name: ADMIN_ENDPOINT
    value: {{ $ctx.Values.console.endpoint | quote }}
  {{- end }}

  {{- if $ctx.Values.console.disableLocalhost }}
  - name: ADMIN_DISABLE_LOCALHOST
    value: "true"
  {{- end }}

  {{- if $ctx.Values.nodeEnv }}
  - name: NODE_ENV
    value: {{ $ctx.Values.nodeEnv | quote }}
  {{- end }}
  {{- if $ctx.Values.databaseStatementTimeout }}
  - name: DATABASE_STATEMENT_TIMEOUT
    value: {{ $ctx.Values.databaseStatementTimeout | quote }}
  {{- end }}
  {{- if $ctx.Values.httpsCertPath }}
  - name: HTTPS_CERT_PATH
    value: {{ $ctx.Values.httpsCertPath | quote }}
  {{- else if $embeddedTls.enabled }}
  - name: HTTPS_CERT_PATH
    value: {{ printf "/etc/logto/tls/%s" $embeddedTls.secret.certName | quote }}
  {{- end }}
  {{- if $ctx.Values.httpsKeyPath }}
  - name: HTTPS_KEY_PATH
    value: {{ $ctx.Values.httpsKeyPath | quote }}
  {{- else if $embeddedTls.enabled }}
  - name: HTTPS_KEY_PATH
    value: {{ printf "/etc/logto/tls/%s" $embeddedTls.secret.keyName | quote }}
  {{- end }}
  {{- if $ctx.Values.trustProxyHeader }}
  - name: TRUST_PROXY_HEADER
    value: {{ $ctx.Values.trustProxyHeader | quote }}
  {{- end }}
  {{- if $ctx.Values.caseSensitiveUsername }}
  - name: CASE_SENSITIVE_USERNAME
    value: {{ $ctx.Values.caseSensitiveUsername | quote }}
  {{- end }}
  {{- if $ctx.Values.secretVaultKek }}
  - name: SECRET_VAULT_KEK
    value: {{ $ctx.Values.secretVaultKek | quote }}
  {{- end }}
{{- with $ctx.Values.envFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or $ctx.Values.volumeMounts $embeddedTls.enabled }}
volumeMounts:
  {{- with $ctx.Values.volumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- if $embeddedTls.enabled }}
  - name: embedded-tls
    mountPath: /etc/logto/tls
    readOnly: true
  {{- end }}
{{- end }}
{{- end -}}
{{- define "logto.waitForDbContainerSpec" -}}
image: postgres:15-alpine
imagePullPolicy: {{ .Values.image.pullPolicy }}
env:
  - name: CI
    value: 'true'
  {{- if .Values.dbUrl.valueFrom }}
  - name: DB_URL
    valueFrom:
      {{- toYaml .Values.dbUrl.valueFrom | nindent 6 }}
  {{- else if .Values.dbUrl.value }}
  - name: DB_URL
    value: {{ .Values.dbUrl.value | quote }}
  {{- end }}
{{- with .Values.envFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
command:
  - /bin/sh
  - -c
  - |
    HP_RAW=$(echo "$DB_URL" | sed -e 's|^.*://||' -e 's|^.*@||' -e 's|/.*$||')  
    HOST=$(echo "$HP_RAW" | cut -d':' -f1)  
    PORT=$(echo "$HP_RAW" | grep ":" | cut -d':' -f2) 
    PORT=${PORT:-5432}  
    DBNAME=$(echo "$DB_URL" | sed -e 's|^.*/||' -e 's|?.*$||')  
    DBNAME=${DBNAME:-postgres}  

    until pg_isready -h "$HOST" -p "$PORT" -d "$DBNAME" -t 2; do
      echo "Waiting for database: $DBNAME at $HOST:$PORT"
      sleep 2
    done
    echo "Database is ready: $DBNAME at $HOST:$PORT"
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
{{- if .Values.console.service.name -}}
{{- .Values.console.service.name -}}
{{- else -}}
{{- include "logto.fullname" . }}-console
{{- end -}}
{{- end -}}
{{/*
Return the core service name for logto
*/}}
{{- define "logto.coreServiceName" -}}
{{- if .Values.service.name -}}
{{- .Values.service.name -}}
{{- else -}}
{{- include "logto.fullname" . }}-core
{{- end -}}
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
{{- define "logto.installPreAppJob" -}}
{{- if or .Values.autoAlteration.enabled .Values.autoSeeding.enabled .Values.deployOfficialConnectors -}}
true
{{- end -}}
{{- end -}}
{{- define "logto.preAppJobName" }}
{{- printf "%s-pre-app-job" (include "logto.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}