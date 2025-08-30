---
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
  labels:
    app.kubernetes.io/name: argocd
    goldilocks.fairwinds.com/enabled: "true"
    pod-security.kubernetes.io/enforce: privileged
# ---
# #####   DEPLOYS IN CLUSTER WHICH ARGO NEEDS TO DEPLOY SERVICES
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: argocd-manager
#   namespace: kube-system
# ---
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: argocd-manager
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: cluster-admin
# subjects:
# - kind: ServiceAccount
#   name: argocd-manager
#   namespace: kube-system 
# ---
# # Change the Vault Address to match yours (base64 encoded)
# apiVersion: v1
# data:
#   ARGOCD_ENV_VAULT_ADDR: ${vault_addr}
# kind: Secret
# metadata:
#   name: argocd-vault-replacer-secret
#   namespace: argocd
# type: Opaque
# ---
# ### FOR INTEGRATION WITH VAULT

# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: cmp-plugin
#   namespace: argocd
#   labels:
#     app.kubernetes.io/name: argocd-cm
#     app.kubernetes.io/part-of: argocd
# data:
#   avp-helm.yaml: |
#     ---
#     apiVersion: argoproj.io/v1alpha1
#     kind: ConfigManagementPlugin
#     metadata:
#       name: argocd-vault-plugin-helm
#     spec:
#       allowConcurrency: true
#       discover:
#         find:
#           command:
#             - sh
#             - "-c"
#             - "find . -name 'Chart.yaml' && find . -name 'values.yaml'"
#       generate:
#        command:
#          - bash
#          - "-c"
#          - |
#            helm template $ARGOCD_APP_NAME -n $ARGOCD_APP_NAMESPACE -f $ARGOCD_ENV_RELEASE_VALUES . |
#            argocd-vault-plugin generate -s vault-configuration -
           

#       lockRepo: false
#   avp.yaml: |
#     apiVersion: argoproj.io/v1alpha1
#     kind: ConfigManagementPlugin
#     metadata:
#       name: argocd-vault-plugin
#     spec:
#       allowConcurrency: true
#       discover:
#         find:
#           command:
#             - sh
#             - "-c"
#             - "find . -name '*.yaml' | xargs -I {} grep \"<path\\|avp\\.kubernetes\\.io\" {} | grep ."
#       generate:
#         command:
#           - argocd-vault-plugin
#           - generate
#           - "."
#           - "-s"
#           - "vault-configuration"
#       lockRepo: false
#   configManagementPlugins: |-
#     - name: argocd-vault-replacer
#       generate:
#         command: ["argocd-vault-replacer"]
#     - name: kustomize-argocd-vault-replacer
#       generate:
#         command: ["sh", "-c"]
#         args: ["kustomize build . | argocd-vault-replacer"]
#     - name: helm-argocd-vault-replacer
#       init:
#         command: ["/bin/sh", "-c"]
#         args: ["helm dependency build"]
#       generate:
#         command: [sh, -c]
#         args: ["helm template -n $ARGOCD_APP_NAMESPACE $ARGOCD_APP_NAME . | argocd-vault-replacer"]
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
