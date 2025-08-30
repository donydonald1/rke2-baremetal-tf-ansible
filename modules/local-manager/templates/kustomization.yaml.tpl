apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: elastic-system
resources:
  - eck-namespace.yaml
  - eck-elasticseach-cert.yaml
  - eck-elasticsearch-ingress.yaml
  - eck-elasticsearch.yaml
  - eck-filebeat.yaml
  - eck-kibana.yaml
  - eck-kibana-ingress.yaml
  - eck-kibana-certs.yaml
  - eck-logstash-cert.yaml
  - eck-logstash.yaml
  #   - es-monitoring.yaml
  #   - kb-monitoring.yaml
  #   - kb-monitoring-ingress.yaml
  - kibana-space-role-rolemapping.yaml
  # - es-delete-old-logs-ilm.yaml
  # - es-cronjob.yaml
  #   - metricbeat.yaml
