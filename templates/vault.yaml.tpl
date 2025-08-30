# ---
# apiVersion: v1
# kind: Namespace
# metadata:
#   name: vault
#   labels:
#     app.kubernetes.io/name: vault
#     goldilocks.fairwinds.com/enabled: "true"
#     pod-security.kubernetes.io/enforce: privileged
# ---
# apiVersion: helm.cattle.io/v1
# kind: HelmChart
# metadata:
#   name: vault-operator
#   namespace: kube-system
# spec:
#   chart: vault-operator
#   repo: oci://ghcr.io/bank-vaults/helm-charts
#   version: 1.22.5
#   targetNamespace: vault
#   # bootstrap: true
#   valuesContent: |-

# ---
# ${vault}