apiVersion: v1
kind: Namespace
metadata:
    name: nfs-local-path-provisioner
    labels:
        goldilocks.fairwinds.com/enabled: "true"
        pod-security.kubernetes.io/enforce: privileged
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
    name: nfs-local-path-provisioner
    namespace: kube-system
spec:
    chart: local-path-provisioner
    repo: https://charts.containeroo.ch
    targetNamespace: nfs-local-path-provisioner
    bootstrap: true
    valuesContent: |-
        ${values}