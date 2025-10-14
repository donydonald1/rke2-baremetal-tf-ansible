{{/*
Expand the name of the chart.
*/}}
{{- define "cnpg-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "cnpg-cluster.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cnpg-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cnpg-cluster.labels" -}}
helm.sh/chart: {{ include "cnpg-cluster.chart" . }}
{{ include "cnpg-cluster.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cnpg-cluster.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cnpg-cluster.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Total memory in MB allocated to a PostgreSQL pod
*/}}
{{- define "cnpg-cluster.totalMemoryMB" -}}
{{- $mem := .Values.resources.requests.memory -}}
{{- if hasSuffix "Gi" $mem -}}
  {{- trimSuffix "Gi" $mem | float64 | mulf 1024 | int -}}
{{- else if hasSuffix "Mi" $mem -}}
  {{- trimSuffix "Mi" $mem | int -}}
{{- else if hasSuffix "G" $mem -}}
  {{- trimSuffix "G" $mem | float64 | mulf 1000 | int -}}
{{- else if hasSuffix "M" $mem -}}
  {{- trimSuffix "M" $mem | int -}}
{{- else -}}
  {{- div (int $mem) 1048576 -}}
{{- end -}}
{{- end }}

{{/*
shared_buffers = 25% total memory
Recommended for mixed workloads (OLTP + analytical queries)
*/}}
{{- define "cnpg-cluster.sharedBuffersMB" -}}
{{- $total := include "cnpg-cluster.totalMemoryMB" . | int -}}
{{- div (mul $total 25) 100 -}}
{{- end }}

{{/*
max_connections = Based on memory and expected workload
Formula: (~totalMemoryMB / 10) capped between 25-200
*/}}
{{- define "cnpg-cluster.maxConnections" -}}
{{- $total := include "cnpg-cluster.totalMemoryMB" . | int -}}
{{- $calculated := div $total 10 -}}
{{- $min := 25 -}}
{{- $max := 200 -}}
{{- if lt $calculated $min -}}
  {{- $min -}}
{{- else if gt $calculated $max -}}
  {{- $max -}}
{{- else -}}
  {{- $calculated -}}
{{- end -}}
{{- end }}

{{/*
Validate that pooler and direct are not both "auto"
*/}}
{{- define "cnpg-cluster.validateConnections" -}}
{{- $pooler := .Values.connections.pooler | toString -}}
{{- $direct := .Values.connections.direct | toString -}}
{{- if and (eq $pooler "auto") (eq $direct "auto") -}}
  {{- fail "Error: connections.pooler and connections.direct cannot both be set to 'auto'" -}}
{{- end -}}
{{- end }}

{{/*
Reserved connections: CNPG, monitoring, migrations, psql, maintenance
*/}}
{{- define "cnpg-cluster.reservedConnections" -}}
{{- .Values.connections.reserved | default 10 | int -}}
{{- end }}

{{/*
Pooler connections: For application traffic via PgBouncer
*/}}
{{- define "cnpg-cluster.poolerConnections" -}}
{{- include "cnpg-cluster.validateConnections" . -}}
{{- $pooler := .Values.connections.pooler | toString -}}
{{- if eq $pooler "auto" -}}
  {{- $max := include "cnpg-cluster.maxConnections" . | int -}}
  {{- $reserved := include "cnpg-cluster.reservedConnections" . | int -}}
  {{- $direct := .Values.connections.direct | int -}}
  {{- $remaining := sub (sub $max $reserved) $direct -}}
  {{- if lt $remaining 0 }}0{{ else }}{{ $remaining }}{{ end }}
{{- else -}}
  {{- $pooler | int -}}
{{- end -}}
{{- end }}

{{/*
Direct connections: Calculated as remaining after system and pooler
*/}}
{{- define "cnpg-cluster.directConnections" -}}
{{- include "cnpg-cluster.validateConnections" . -}}
{{- $direct := .Values.connections.direct | toString -}}
{{- if eq $direct "auto" -}}
  {{- $max := include "cnpg-cluster.maxConnections" . | int -}}
  {{- $reserved := include "cnpg-cluster.reservedConnections" . | int -}}
  {{- $pooler := .Values.connections.pooler | int -}}
  {{- $remaining := sub (sub $max $reserved) $pooler -}}
  {{- if lt $remaining 5 }}5{{ else }}{{ $remaining }}{{ end }}
{{- else -}}
  {{- $direct | int -}}
{{- end -}}
{{- end }}

{{/*
Pooler max_db_connections
*/}}
{{- define "cnpg-cluster.pooler.maxDbConnections" -}}
{{- include "cnpg-cluster.poolerConnections" . -}}
{{- end }}

{{/*
work_mem = (Total RAM * 0.25) / max_connections
Minimum 4MB for reasonable query performance
*/}}
{{- define "cnpg-cluster.workMemMB" -}}
{{- $total := include "cnpg-cluster.totalMemoryMB" . | int -}}
{{- $maxConn := include "cnpg-cluster.maxConnections" . | int -}}
{{- $quarter := div (mul $total 25) 100 -}}
{{- $per := div $quarter $maxConn -}}
{{- if lt $per 4 }}4{{ else }}{{ $per }}{{ end }}
{{- end }}

{{/*
maintenance_work_mem = min(10% total, 2GB)
Higher values speed up VACUUM, CREATE INDEX
*/}}
{{- define "cnpg-cluster.maintenanceWorkMemMB" -}}
{{- $total := include "cnpg-cluster.totalMemoryMB" . | int -}}
{{- $calculated := div (mul $total 10) 100 -}}
{{- $max := 2048 -}}
{{- if gt $calculated $max }}{{ $max }}{{ else }}{{ $calculated }}{{ end }}
{{- end }}

{{/*
effective_cache_size = 75% total memory
Assumption: Kubernetes node has some free memory for OS cache
PostgREST benefits from accurate planner estimates
*/}}
{{- define "cnpg-cluster.effectiveCacheSizeMB" -}}
{{- $total := include "cnpg-cluster.totalMemoryMB" . | int -}}
{{- div (mul $total 75) 100 -}}
{{- end }}

{{/*
random_page_cost: Lower for SSD storage (default 4.0 is for HDD)
*/}}
{{- define "cnpg-cluster.randomPageCost" -}}
1.1
{{- end }}

{{/*
effective_io_concurrency: Higher for SSD/NVMe
*/}}
{{- define "cnpg-cluster.effectiveIOConcurrency" -}}
200
{{- end }}

{{/*
Pooler sizing helpers
For transaction pooling mode
*/}}
{{- define "cnpg-cluster.pooler.maxClientConn" -}}
{{- $db := include "cnpg-cluster.pooler.maxDbConnections" . | int -}}
{{- if gt $db 0 -}}
  {{- $calc := mul $db 15 -}}
  {{- if lt $calc 2000 -}}2000{{- else -}}2000{{- end -}}
{{- else -}}
2000
{{- end -}}
{{- end }}

{{- define "cnpg-cluster.pooler.defaultPoolSize" -}}
{{- /* 70% of max_db_connections for transaction mode */ -}}
{{- $db := include "cnpg-cluster.pooler.maxDbConnections" . | int -}}
{{- if gt $db 0 -}}
  {{- $v := div (mul $db 2000) 2000 -}}
  {{- if lt $v 5 }}5{{ else }}{{ $v }}{{ end }}
{{- else -}}
  2000
{{- end -}}
{{- end }}

{{- define "cnpg-cluster.now" -}}
{{- $tz := .Values.timezone | default "Local" -}}
{{- dateInZone "2006-01-02T15:04:05-07:00" (now) $tz -}}
{{- end }}

{{/*
Schedule for automatic backups
*/}}
{{- define "cnpg-cluster.randomBackupSchedule" -}}
{{- $seed := adler32sum (printf "%s-%s" .Release.Name .Release.Namespace) -}}
{{- $offset := mod $seed 120 -}}
{{- $hour := add 19 (div $offset 60) -}}
{{- $minute := mod $offset 60 -}}
{{- printf "0 %02d %d * * *" $minute $hour -}}
{{- end }}
{{- define "cnpg-cluster.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}