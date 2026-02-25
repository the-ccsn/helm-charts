{{/*
Return the dict of all services (core/admin)
Usage: include "logto.serviceDict" .
*/}}
{{- define "logto.serviceDict" -}}
{{ dict "core" .Values.service "admin" .Values.console.service }}
{{- end -}}
{{/*
Return the service name for logto by name
Usage: include "logto.serviceName" (dict "root" $ "name" svcName)
*/}}
{{- define "logto.serviceName" -}}
{{- define "logto.coreServiceName" -}}
{{ include "logto.fullname" . }}-{{ .Values.service.name }}
{{- end -}}
{{ include "logto.coreServiceName" $ }}
{{- else if eq $name $.Values.services.admin.name -}}
{{ include "logto.adminServiceName" $ }}
{{- else -}}
{{- define "logto.adminServiceName" -}}
{{ include "logto.fullname" . }}-{{ .Values.console.service.name }}
{{- end -}}

{{/*
Return the service port for logto by name
Usage: include "logto.servicePort" (dict "root" $ "name" svcName)
{{- define "logto.coreServicePort" -}}
{{ .Values.service.port }}
{{- end -}}
{{- $name := .name -}}
{{- if eq $name $.Values.services.core.name -}}
{{ include "logto.coreServicePort" $ }}
{{- else if eq $name $.Values.services.admin.name -}}
{{- define "logto.adminServicePort" -}}
{{ .Values.console.service.port }}
{{- end -}}
{{- $svc := (index $.Values.services $name) -}}
{{- if $svc -}}
{{ $svc.port }}
{{- end -}}
{{- end -}}
{{- end -}}
{{/*
Return the core service port for logto
*/}}
{{- define "logto.coreServicePort" -}}
{{ .Values.services.core.port }}
{{- end -}}

{{/*
Return the admin service port for logto
*/}}
{{- define "logto.adminServicePort" -}}
{{ .Values.services.admin.port }}
{{- end -}}
{{/*
Return the admin service name for logto
*/}}
{{- define "logto.adminServiceName" -}}
{{ include "logto.fullname" . }}-{{ .Values.services.admin.name }}
{{- end -}}
{{/*
Return the core service name for logto
*/}}
{{- define "logto.coreServiceName" -}}
{{ include "logto.fullname" . }}-{{ .Values.services.core.name }}
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
