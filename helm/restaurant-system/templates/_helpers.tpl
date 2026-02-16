{{/*
Expand the name of the chart.
*/}}
{{- define "restaurant-system.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "restaurant-system.fullname" -}}
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
{{- define "restaurant-system.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "restaurant-system.labels" -}}
helm.sh/chart: {{ include "restaurant-system.chart" . }}
{{ include "restaurant-system.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "restaurant-system.selectorLabels" -}}
app.kubernetes.io/name: {{ include "restaurant-system.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
API Gateway labels
*/}}
{{- define "restaurant-system.apiGateway.labels" -}}
{{ include "restaurant-system.labels" . }}
app: {{ .Values.apiGateway.name }}
{{- end }}

{{/*
Auth Service labels
*/}}
{{- define "restaurant-system.authService.labels" -}}
{{ include "restaurant-system.labels" . }}
app: {{ .Values.authService.name }}
{{- end }}

{{/*
Restaurant Service labels
*/}}
{{- define "restaurant-system.restaurantService.labels" -}}
{{ include "restaurant-system.labels" . }}
app: {{ .Values.restaurantService.name }}
{{- end }}

{{/*
POS Service labels
*/}}
{{- define "restaurant-system.posService.labels" -}}
{{ include "restaurant-system.labels" . }}
app: {{ .Values.posService.name }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "restaurant-system.frontend.labels" -}}
{{ include "restaurant-system.labels" . }}
app: {{ .Values.frontend.name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "restaurant-system.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "restaurant-system.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL host
*/}}
{{- define "restaurant-system.postgresql.host" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" .Release.Name }}
{{- else }}
{{- .Values.externalPostgresql.host }}
{{- end }}
{{- end }}

{{/*
Redis host
*/}}
{{- define "restaurant-system.redis.host" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-redis-master" .Release.Name }}
{{- else }}
{{- .Values.externalRedis.host }}
{{- end }}
{{- end }}
