---
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
  labels:
    app.kubernetes.io/name: argocd
    goldilocks.fairwinds.com/enabled: "true"
    pod-security.kubernetes.io/enforce: privileged
---
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: argocd
  namespace: kube-system
spec:
  chart: argo-cd
  repo: https://argoproj.github.io/argo-helm
  targetNamespace: argocd
  valuesContent: |-
    ${values}
