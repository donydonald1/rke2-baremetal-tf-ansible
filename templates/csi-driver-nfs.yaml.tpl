apiVersion: v1
kind: Namespace
metadata:
    name: csi-driver-nfs
    labels:
        goldilocks.fairwinds.com/enabled: "true"
        pod-security.kubernetes.io/enforce: privileged
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
    name: csi-driver-nfs
    namespace: kube-system
spec:
    chart: csi-driver-nfs
    repo: https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
    targetNamespace: csi-driver-nfs
    bootstrap: true
    valuesContent: |-
        ${values}