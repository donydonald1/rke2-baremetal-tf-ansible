---
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
  labels:
    goldilocks.fairwinds.com/enabled: "true"
    pod-security.kubernetes.io/enforce: privileged
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: external-secrets
  namespace: kube-system
spec:
  chart: external-secrets
  repo: https://charts.external-secrets.io
  targetNamespace: external-secrets
  bootstrap: true
  valuesContent: |-
    ${values}