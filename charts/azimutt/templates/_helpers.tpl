{{/*
Expand the name of the chart.
*/}}
{{- define "azimutt.name" -}}
{{- default .Chart.Name .Values.azimutt.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "azimutt.fullname" -}}
{{- if .Values.azimutt.fullnameOverride }}
{{- .Values.azimutt.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.azimutt.nameOverride }}
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
{{- define "azimutt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "azimutt.labels" -}}
helm.sh/chart: {{ include "azimutt.chart" . }}
{{ include "azimutt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "azimutt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "azimutt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "azimutt.serviceAccountName" -}}
{{- if .Values.azimutt.serviceAccount.create }}
{{- default (include "azimutt.fullname" .) .Values.azimutt.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.azimutt.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the email provider
*/}}
{{- define "azimutt.emailProvider" -}}
{{- if .Values.azimutt.configuration.email.mailgun.enabled -}}
mailgun
{{- else if .Values.azimutt.configuration.email.gmail.enabled -}}
gmail
{{- else if .Values.azimutt.configuration.email.smtp.enabled -}}
smtp
{{- end -}}
{{- end -}}