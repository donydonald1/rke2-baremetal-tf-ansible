---
apiVersion: v1
kind: Namespace
metadata:
  name: vault
  labels:
    goldilocks.fairwinds.com/enabled: "true"
    pod-security.kubernetes.io/enforce: privileged
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: vault
  name: vault-config-manager
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "update", create]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: vault
  name: vault-config-manager
subjects:
- kind: ServiceAccount
  name: vault-config-manager
  namespace: vault
- kind: ServiceAccount
  name: vault
  namespace: vault
roleRef:
  kind: Role
  name: vault-config-manager
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-config-manager
  namespace: vault
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-config-manager
  namespace: vault
stringData:
  vault-configure.yaml: |
    auth:
      - type: userpass
        config: {}
        users:
        - username: "${username}"
          password: "${vault_admin_password}"
          policies: superadmin
      - type: kubernetes
        config:
            # uses vault Service Account
            kubernetes_host: https://kubernetes.default.svc.cluster.local
        roles:
          - name: allow-secrets
            bound_service_account_names:
              - external-secrets
              - argocd
            bound_service_account_namespaces:
              - external-secrets
              - argocd
            policies:
              - allow_secrets
            ttl: 1h
          - name: allow-pki
            bound_service_account_names:
              - cert-manager
              - argocd
            bound_service_account_namespaces:
              - cert-manager
              - argocd
            policies:
              - allow_pki
            ttl: 1h
      - type: jwt
        config:
          bound_issuer: "https://token.actions.githubusercontent.com"
          oidc_discovery_url: "https://token.actions.githubusercontent.com"
          default_role: robot
        roles:
        - name: robot
          role_type: jwt
          user_claim: "actor"
          bound_claims_type: "glob"
          bound_claims:
            repository: "Techsecom/*"
          policies: superadmin
    policies:
      - name: superadmin
        rules: path "*" {
                capabilities = ["create", "read", "update", "delete", "list", "sudo"]
              }
      - name: allow_secrets
        rules: path "secret/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
          }
      - name: allow_pki
        rules: path "*" {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
          }
    secrets:
      - path: secret
        type: kv
        description: General secrets.
        options:
          version: 2

    audit:
      - type: file
        description: "File based audit logging device"
        options:
          file_path: /dev/stdout
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: configure
  namespace: vault
  labels:
    app: configure
    pod-security.kubernetes.io/enforce: privileged
spec:
  replicas: 1
  selector:
    matchLabels:
      app: configure
  template:
    metadata:
      labels:
        app: configure
    spec:
      serviceAccountName: vault-config-manager
      initContainers:
      - name: init
        image: ghcr.io/bank-vaults/bank-vaults
        args:
          - init
          - --mode
          - k8s
          - --k8s-secret-name
          - vault-seal
          - --k8s-secret-namespace
          - vault
        env:
          - name: VAULT_ADDR
            value: http://vault-internal:8200
      containers:
      - name: configure
        image: ghcr.io/bank-vaults/bank-vaults
        args:
          - configure
          - --mode
          - k8s
          - --k8s-secret-name
          - vault-seal
          - --k8s-secret-namespace
          - vault
          - --vault-config-file
          - /vault/autoconfig/vault-configure.yaml
        env:
          - name: VAULT_ADDR
            value: http://vault-active:8200
        volumeMounts:
        - name: vault-config-manager
          mountPath: /vault/autoconfig
      volumes:
        - name: vault-config-manager
          secret:
            secretName: vault-config-manager
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: vault
  namespace: kube-system
spec:
  chart: vault
  repo: https://helm.releases.hashicorp.com
  targetNamespace: vault
  bootstrap: true
  valuesContent: |-
    ${values}

