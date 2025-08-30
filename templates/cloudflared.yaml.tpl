---
apiVersion: v1
kind: Namespace
metadata:
  name: cloudflared
  labels:
    goldilocks.fairwinds.com/enabled: "true"
    pod-security.kubernetes.io/enforce: privileged
---
${values}
