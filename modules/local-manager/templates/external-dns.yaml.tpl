---
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns
  labels:
    goldilocks.fairwinds.com/enabled: "true"
    pod-security.kubernetes.io/enforce: privileged
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: external-dns
  namespace: kube-system
spec:
  chart: external-dns
  repo: https://kubernetes-sigs.github.io/external-dns
  targetNamespace: external-dns
  bootstrap: true
  valuesContent: |-
    ${values}
