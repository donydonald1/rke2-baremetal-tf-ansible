resource "kubernetes_secret" "cloudflared_credentials" {
  metadata {
    name      = "cloudflared-credentials"
    namespace = kubernetes_namespace.this["cloudflared"].metadata[0].name

    annotations = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    "credentials.json" = jsonencode({
      AccountTag   = var.cloudflare_account_id
      TunnelName   = var.cluster_name
      TunnelID     = module.cloudflare.tunnel_id
      TunnelSecret = base64encode(module.cloudflare.tunnel_id_random_password)
    })
  }
  depends_on = [module.kubeconfig]
}


resource "kubernetes_namespace" "this" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.key
  }

  depends_on = [module.kubeconfig]
}

resource "kubernetes_secret" "external_dns_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace.this["external-dns"].metadata[0].name

    annotations = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    "value" = module.cloudflare.cloudflare_api_token
  }
  depends_on = [kubernetes_namespace.this]
}

resource "kubernetes_secret" "cert_manager_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = kubernetes_namespace.this["cert-manager"].metadata[0].name

    annotations = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    "api-token" = module.cloudflare.cert_manager_issuer_token
  }
  depends_on = [kubernetes_namespace.this]
}

resource "kubectl_manifest" "vault_sa" {
  yaml_body  = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault
  namespace: vault
YAML
  depends_on = [helm_release.vault_operator]

}

resource "kubectl_manifest" "vault_role" {
  yaml_body  = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: vault
  namespace: vault
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch", "create", "update"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "update", "patch"]
YAML
  depends_on = [helm_release.vault_operator]

}

resource "kubectl_manifest" "vault_rolebinding" {
  yaml_body  = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: vault
  namespace: vault
roleRef:
  kind: Role
  name: vault
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: vault
    namespace: vault
YAML
  depends_on = [helm_release.vault_operator]

}


resource "kubectl_manifest" "vault_clusterrolebinding" {
  yaml_body  = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: vault
    namespace: vault
YAML
  depends_on = [helm_release.vault_operator]

}

resource "kubectl_manifest" "clusterissuer_letsencrypt_prod" {
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
YAML
  depends_on = [null_resource.kustomization]
}

resource "kubectl_manifest" "external_secret_vault" {
  yaml_body  = <<YAML
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: https://vault.vault.svc.cluster.local:8200
      path: secret
      caProvider:
        type: Secret
        name: vault-tls
        namespace: vault
        key: ca.crt
      auth:
        kubernetes:
          mountPath: kubernetes
          role: allow-secrets
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
YAML
  depends_on = [null_resource.kustomization, helm_release.vault_operator, ]
}

resource "kubectl_manifest" "app_projects" {
  for_each = toset(var.argocd_project_names)

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: ${each.value}
  namespace: argocd
spec:
  description: Project for control-plane and administrative components necessitating a fully permissive structure
  sourceRepos:
    - '*'  # Allow all repositories
  destinations:
    - namespace: '*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
YAML

  depends_on = [kubernetes_config_map.cmp-plugin, null_resource.kustomization, helm_release.vault_operator]
}

resource "kubernetes_config_map" "cmp-plugin" {
  metadata {
    name      = "avp-cmp-plugin"
    namespace = "argocd"
  }
  data = {
    "avp-kustomize.yaml" = templatefile("${path.module}/templates/avp-kustomize.yaml", { name = "avp-kustomize" })
    "avp-helm.yaml"      = templatefile("${path.module}/templates/avp-helm.yaml", { name = "avp-helm" })
    "avp-k8s.yaml"       = templatefile("${path.module}/templates/avp-k8s.yaml", { name = "avp-k8s" })
  }
  depends_on = [null_resource.kustomization]
}

# resource "kubectl_manifest" "argocd_apps-of-apps" {
#   yaml_body  = <<YAML
# apiVersion: argoproj.io/v1alpha1
# kind: Application
# metadata:
#   name: app-of-apps
#   namespace: argocd
#   annotations:
#     argocd.argoproj.io/sync-wave: "1"
#   finalizers:
#     - resources-finalizer.argocd.argoproj.io
# spec:
#   project: main
#   source:
#     repoURL: ${var.argocd_tamplate_repo_url}
#     path: apps-of-apps/
#     targetRevision: HEAD
#   destination:
#     name: in-cluster
#     namespace: argocd
#   syncPolicy:
#     syncOptions:
#       - CreateNamespace=true
#     automated:
#       selfHeal: true
#       prune: true
# YAML
#   depends_on = [kubernetes_config_map.cmp-plugin, helm_release.vault_operator]
# }

resource "kubectl_manifest" "vault" {
  yaml_body = <<YAML
apiVersion: "vault.banzaicloud.com/v1alpha1"
kind: "Vault"
metadata:
  name: "vault"
  labels:
    backup/retain: quaterly
  namespace: "${helm_release.vault_operator.namespace}"
spec:
  size: 3
  # renovate: datasource=docker
#   image: hashicorp/vault:1.18.5
  veleroEnabled: false
  # Common annotations for all created resources
  annotations:
    common/annotation: "true"
  vaultAnnotations:
    type/instance: "vault"
  vaultConfigurerAnnotations:
    type/instance: "vaultconfigurer"
  vaultLabels:
    example.com/log-format: "json"
  vaultConfigurerLabels:
    example.com/log-format: "string"
  serviceAccount: vault
  serviceType: ClusterIP
  # tlsExpiryThreshold: 168h
  securityContext:
    runAsUser: 100
    runAsGroup: 100
    runAsNonRoot: true
    fsGroup: 100
    fsGroupChangePolicy: "OnRootMismatch"
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      external-dns.alpha.kubernetes.io/enabled: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    spec:
      ingressClassName: nginx
      rules:
      - host: ${var.vault_hostname}
        http:
          paths:
          - backend:
              service:
                name: vault
                port:
                  number: 8200
            path: /
            pathType: Prefix
      tls:
      - hosts:
        - ${var.vault_hostname}
        secretName: vault-tls-certificate

  volumeClaimTemplates:
    - metadata:
        name: vault-raft
      spec:
        accessModes:
          - ReadWriteMany
        resources:
          requests:
            storage: 1Gi
        storageClassName: nfs-csi
        volumeMode: Filesystem
  volumeMounts:
    - mountPath: /vault/file
      name: vault-raft
  # Describe where you would like to store the Vault unseal keys and root token.
  unsealConfig:
    options:
      storeRootToken: true
      secretShares: 5
      secretThreshold: 3
    kubernetes:
      secretNamespace: vault

  config:
    disable_mlock: true
    storage:
      raft:
        path: "/vault/file"
    telemetry:
      statsd_address: 'localhost:9125'
    listener:
      tcp:
        telemetry:
          unauthenticated_metrics_access: true
        address: "0.0.0.0:8200"
        tls_cert_file: /vault/tls/server.crt
        tls_key_file: /vault/tls/server.key
    api_addr: "https://vault.vault.svc.cluster.local:8200"
    cluster_addr: "https://$${.Env.POD_NAME}:8201"
    ui: true
  # resources:
  #   # A YAML representation of resource ResourceRequirements for vault container
  #   # Detail can reference: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container
  #   vault:
  #     limits: {}
  #     requests:
  #       memory: "512Mi"
  #       cpu: 1
  caNamespaces:
    - "*"
  serviceRegistrationEnabled: true
  vaultEnvsConfig:
  - name: VAULT_LOG_LEVEL
    value: info
  - name: VAULT_STORAGE_FILE
    value: "/vault/file"
  - name: SKIP_SETCAP
    value: 'true'
  - name: SKIP_CHOWN
    value: 'true'

  istioEnabled: false
#   envsConfig:
#   - name: OIDC_CLIENT_SECRET
#     valueFrom:
#       secretKeyRef:
#         name: vault-secrets
#         key: OIDC_CLIENT_SECRET

  externalConfig:
    auth:
    - type: kubernetes
      path: kubernetes
      config:
        kubernetes_host: https://kubernetes.default.svc.cluster.local
      roles:
      - name: allow-secrets
        bound_service_account_names:
          - external-secrets
        bound_service_account_namespaces:
          - external-secrets
        policies:
          - allow_secrets
        ttl: 1h
      - name: allow-iot-pki
        bound_service_account_names:
          - cert-manager
        bound_service_account_namespaces:
          - cert-manager
        policies:
          - allow_iot_pki
        ttl: 1h
    - type: oidc
      path: oidc
      options:
        listing_visibility: "unauth"
      config:
        oidc_discovery_url: ${var.vault_oidc_discovery_url}
        oidc_client_id: ${var.vault_oidc_client_id}
        oidc_client_secret: ${var.vault_oidc_client_secret}
        default_role: admin
        jwt_supported_algs:
        - ES256
        - RS256
      roles:
      - name: default
        allowed_redirect_uris:
        - https://${var.vault_hostname}/ui/vault/auth/oidc/oidc/callback
        - http://localhost:8250/oidc/callback
        user_claim: email
        oidc_scopes: 
        - email 
        - profile 
        - openid
        # groups_claim: groups
        policies: admin
        ttl: 1h

    secrets:
    - path: secret
      type: kv
      description: General secrets.
      options:
        version: 2
    # https://learn.hashicorp.com/tutorials/vault/pki-engine
    - type: pki
      path: pki/techsecom
      description: Techsecom root CA
      config:
        default_lease_ttl: "9528h" # 397 days -> max certificate validity
        max_lease_ttl: "87600h" # 10 years
      configuration:
        config:
        - name: urls
          issuing_certificates:
          - https://${var.vault_hostname}/v1/pki/techsecom/ca
          crl_distribution_points:
          - https://${var.vault_hostname}/v1/pki/techsecom/crl
        roles:
        - name: internal-certificates-${var.domain}
          allow_localhost: false
          ttl: "9528h"
          max_ttl: "9528h"
          allow_glob_domains: true
          allowed_domains:
          - "*.${var.domain}"
          allow_subdomains: true
          server_flag: true
          client_flag: false
          key_type: "rsa"
          key_bits: 4096
          signature_bits: 256
          organization: "${var.vault_organization}"
          country: "USA"
          locality: "Texas"
          province: "Dallas"
          allowed_domains_template: false
          issuer_ref: "default"
    - type: pki
      path: pki/iot
      description: ${var.vault_organization} IoT root CA
      config:
        default_lease_ttl: "9528h" # 397 days -> max certificate validity
        max_lease_ttl: "87600h" # 10 years
      configuration:
        config:
        - name: urls
          issuing_certificates:
          - https://${var.vault_hostname}/v1/pki/iot/ca
          crl_distribution_points:
          - https://${var.vault_hostname}/v1/pki/iot/crl
        root/generate:
        - name: internal
          common_name: prod.${var.domain}
          ttl: "87600h"
          allow_subdomains: true
          allow_wildcard_certificates: true
          allowed_domains:
          - "*.iot.${var.domain}"
          - "*.dev.${var.domain}"
          - "*.internal.${var.domain}"
          key_type: "rsa"
          key_bits: 4096
          organization: "${var.vault_organization}"
          country: "USA"
          locality: "Texas"
          province: "Dallas"
        roles:
        - name: internal-certificates-${var.domain}-iot
          allow_localhost: false
          ttl: "9528h"
          max_ttl: "9528h"
          allow_glob_domains: true
          allowed_domains:
          - "*.iot.${var.domain}"
          - "*.dev.${var.domain}"
          - "*.internal.${var.domain}"
          allow_subdomains: true
          server_flag: true
          client_flag: false
          key_type: "rsa"
          key_bits: 4096
          signature_bits: 256
          organization: "${var.vault_organization}"
          country: "USA"
          locality: "Texas"
          province: "Dallas"
          allowed_domains_template: false
          issuer_ref: "default"
    policies:
    - name: allow_secrets
      rules: |-
        path "secret/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
    - name: allow_iot_pki
      rules: |-
        path "pki/iot/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
    - name: admin
      rules: |-
        # Read system health check
        path "sys/health"
        {
          capabilities = ["read", "sudo"]
        }

        # Create and manage ACL policies broadly across Vault

        # List existing policies
        path "sys/policies/acl"
        {
          capabilities = ["list"]
        }

        # Create and manage ACL policies
        path "sys/policies/acl/*"
        {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # Enable and manage authentication methods broadly across Vault

        # Manage auth methods broadly across Vault
        path "auth/*"
        {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # Create, update, and delete auth methods
        path "sys/auth/*"
        {
          capabilities = ["create", "update", "delete", "sudo"]
        }

        # List auth methods
        path "sys/auth"
        {
          capabilities = ["read"]
        }

        # Enable and manage the key/value secrets engine at `secret/` path

        # List, create, update, and delete key/value secrets
        path "secret/*"
        {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # List, create, update, and delete key/value secrets
        path "pki/*"
        {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # Manage secrets engines
        path "sys/mounts/*"
        {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }

        # List existing secrets engines.
        path "sys/mounts"
        {
          capabilities = ["read"]
        }
YAML
  depends_on = [
    kubectl_manifest.vault_clusterrolebinding,
    kubectl_manifest.vault_rolebinding,
    kubectl_manifest.vault_role,
    kubectl_manifest.vault_sa,
  ]
}

resource "time_sleep" "sleep-wait-vault" {
  depends_on      = [null_resource.kustomization, kubectl_manifest.vault, helm_release.vault_operator, ]
  create_duration = var.vault_wait_time != null ? var.vault_wait_time : "1s"
}

resource "kubernetes_secret" "vault_credentials" {
  metadata {
    name      = "avp-plugin-credentials"
    namespace = "argocd"
  }
  data = {
    VAULT_ADDR    = "https://${var.vault_hostname}"
    AVP_AUTH_TYPE = "token"
    AVP_TYPE      = "vault"
    VAULT_TOKEN   = "${data.kubernetes_secret_v1.vault_seal.data["vault-root"]}"
    # VAULT_CACERT      = "/vault/tls/vault.ca"
    # VAULT_CAPATH      = "/vault/tls/vault.ca"
    # VAULT_CLIENT_CERT = "/vault/tls/vault.crt"
    # VAULT_CLIENT_KEY  = "/vault/tls/vault.key"
  }
  type       = "Opaque"
  depends_on = [time_sleep.sleep-wait-vault]
}
