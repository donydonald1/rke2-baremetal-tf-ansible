---
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
  labels:
    goldilocks.fairwinds.com/enabled: "true"
    pod-security.kubernetes.io/enforce: privileged
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: metallb
  namespace: kube-system
spec:
  chart: metallb
  repo: https://metallb.github.io/metallb
  targetNamespace: metallb-system
  bootstrap: true
  valuesContent: |-
    ${values}
