apiVersion: audit.k8s.io/v1
kind: Policy
metadata:
  name: rke2-audit-policy
rules:
  - level: Metadata
    resources:
    - group: ""
      resources: ["secrets"]
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["*"]
