locals {
  kustomization_backup_yaml = yamlencode({
    apiVersion = "kustomize.config.k8s.io/v1beta1"
    kind       = "Kustomization"
    resources = concat(
      [
        "https://github.com/rancher/system-upgrade-controller/releases/download/${var.sys_upgrade_controller_version}/system-upgrade-controller.yaml",
        "https://github.com/rancher/system-upgrade-controller/releases/download/${var.sys_upgrade_controller_version}/crd.yaml"
      ],
      var.enable_cert_manager || var.enable_rancher ? ["cert_manager.yaml"] : [],
      var.enable_argocd ? ["argocd.yaml"] : [],
      var.enable_longhorn ? ["longhorn.yaml"] : [],
      var.enable_external_dns ? ["external-dns.yaml"] : [],
      var.enable_external_secrets ? ["external-secrets.yaml"] : [],
      var.rancher_registration_manifest_url != "" ? [var.rancher_registration_manifest_url] : [],
      var.enable_rancher ? ["rancher.yaml"] : [],
      var.enable_csi_driver_nfs ? ["csi-driver-nfs.yaml"] : [],
      var.enable_csi_driver_nfs ? ["csi-driver-nfs-localpath.yaml"] : [],
    ),
    patches = [
      {
        target = {
          group     = "apps"
          version   = "v1"
          kind      = "Deployment"
          name      = "system-upgrade-controller"
          namespace = "system-upgrade"
        }
        patch = file("${path.module}/kustomize/system-upgrade-controller.yaml")
      },
      {
        target = {
          group     = "apps"
          version   = "v1"
          kind      = "Deployment"
          name      = "system-upgrade-controller"
          namespace = "system-upgrade"
        }
        patch = <<-EOF
          - op: replace
            path: /spec/template/spec/containers/0/image
            value: rancher/system-upgrade-controller:${var.sys_upgrade_controller_version}
        EOF
      },
    ]
  })
  cloudflared_values = var.cloudflared_values != "" ? var.cloudflared_values : <<EOT
controllers:
  cloudflared:
    containers:
      app:
        image:
          repository: docker.io/cloudflare/cloudflared
          tag: 2025.2.0
        args:
          - tunnel
          - --config
          - /etc/cloudflared/config.yaml
          - run

configMaps:
  config:
    enabled: true
    data:
      config.yaml: |
        tunnel: ${var.cluster_name}
        credentials-file: /etc/cloudflared/credentials.json
        metrics: 0.0.0.0:2000
        no-autoupdate: false
        ingress:
          - hostname: '*.${var.domain}'
            service: https://ingress-nginx-controller.kube-system.svc.cluster.local
            originRequest:
              noTLSVerify: true
          - service: http_status:404
persistence:
  config:
    enabled: true
    type: configMap
    name: cloudflared
    globalMounts:
      - path: /etc/cloudflared/config.yaml
        subPath: config.yaml
  credentials:
    enabled: true
    type: secret
    # Created by ../../external/cloudflared
    name: cloudflared-credentials
    globalMounts:
      - path: /etc/cloudflared/credentials.json
        subPath: credentials.json
  EOT

  external_dns_values = var.external_dns_values != "" ? var.external_dns_values : <<EOT
interval: 2m
# logLevel: debug
provider: 
  name: cloudflare
env:
  - name: CF_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: cloudflare-api-token
        key: value

extraArgs:
  - --annotation-filter=external-dns.alpha.kubernetes.io/enabled in (true)
# policy sync for fully handle the domain
# policy: upsert-only

sources:
  - service
  - ingress
# domainFilters:
#   - ${var.domain}
# triggerLoopOnEvent: true
interval: 5m
txtOwnerId: ${var.cluster_name}
serviceMonitor:
  enabled: false
  additionalLabels:
    release: monitoring
resources:
  requests:
    cpu: 10m
    memory: 14Mi
  limits:
    memory: 64Mi
  EOT

  external_secrets_values = var.external_secrets_values != "" ? var.external_secrets_values : <<EOT
resources:
  requests:
    cpu: 10m
    memory: 38Mi
  limits:
    memory: 64Mi

extraArgs:
  loglevel: debug

webhook:
  resources:
    requests:
      cpu: 10m
      memory: 21Mi
    limits:
      memory: 64Mi

certController:
  resources:
    requests:
      cpu: 10m
      memory: 64Mi
    limits:
      memory: 128Mi
  EOT

  rancher_values = var.rancher_values != "" ? var.rancher_values : <<EOT
auditLog:
  destination: sidecar
  hostPath: /var/log/rancher/
  level: 0
  maxAge: 1
  maxBackup: 1
  maxSize: 100
  image:
    repository: "rancher/mirrored-bci-micro"
    # tag: 15.6.24.2
    pullPolicy: "IfNotPresent"

ingress:
  enabled: true
  ingressClassName: "${var.ingress_class}"
  includeDefaultExtraAnnotations: true
  extraAnnotations:
    gethomepage.dev/enabled: "true"
    gethomepage.dev/name: Rancher
    gethomepage.dev/description: Kube Cluster mgmt
    gethomepage.dev/group: Services
    gethomepage.dev/icon: rancher.png
    gethomepage.dev/pod-selector: ""
    gethomepage.dev/href: "https://${var.rancher_hostname != "" ? var.rancher_hostname : var.rancher_values}"
    gethomepage.dev/siteMonitor: "https://${var.rancher_hostname != "" ? var.rancher_hostname : var.rancher_values}"
    cert-manager.io/cluster-issuer: letsencrypt-prod
    cert-manager.io/revision-history-limit: "3"
    external-dns.alpha.kubernetes.io/enabled: "true"
    cert-manager.io/duration: "2160h"
    cert-manager.io/renew-before: "720h"
  hosts:
    - host: "${var.rancher_hostname != "" ? var.rancher_hostname : var.rancher_values}"
  tls:
    source: "secret"
    secretName: tls-rancher-ingress
postDelete:
  enabled: true
  image:
    repository: rancher/shell
    # tag: v0.4.0
  namespaceList:
    - cattle-fleet-system
    - cattle-system
    - rancher-operator-system

  timeout: 120
  # by default, the job will fail if it fail to uninstall any of the apps
  ignoreTimeoutError: false
hostname: "${var.rancher_hostname != "" ? var.rancher_hostname : var.rancher_values}"
replicas: ${length(try(module.rke2_metalhost_servers.server_ips, []))}
bootstrapPassword: "${resource.random_password.rancher_bootstrap.result}"
global:
  cattle:
    psp:
      enabled: false
useBundledSystemChart: true
tls: ingress
noProxy: 127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.svc,.cluster.local
  EOT

  vault_values = var.vault_operator_values != "" ? var.vault_operator_values : <<EOT
name: vault-operator
  EOT

  argocd_values = var.argocd_values != "" ? var.argocd_values : <<EOT
crds:
  install: true
  keep: true
global:
  domain: ${var.argocd_hostname}
  env:
    - name: TZ
      value: America/Chicago
    - name: ARGOCD_EXEC_TIMEOUT
      value: 300s
configs:
  cm:
    create: true
    admin.enabled: true
    exec.enabled: true
    url: https://${var.argocd_hostname}
    kustomize.buildOptions: "--enable-helm"
    timeout.reconciliation.jitter: 60s
    timeout.reconciliation: 300s
    statusbadge.enabled: true

    # Keep server-side diff (prevents client-side last-applied use)
    # (You already set this in params; leaving it there too.)
    # application.resourceTrackingMethod: annotation+label  # (optional)

    resource.compareoptions: |
      ignoreAggregatedRoles: true

    # ✨ CRDs: ignore the huge client-side apply blob so Argo CD doesn't try to write or diff it
    resource.customizations.ignoreDifferences.apiextensions.k8s.io_CustomResourceDefinition: |+
      jqPathExpressions:
      - '.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"'

    # ✨ Cluster-wide: also ignore that annotation on *all* resources (helps ConfigMaps like node-exporter-full)
    resource.customizations.ignoreDifferences.all: |+
      jqPathExpressions:
      - '.metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"'
      - '.metadata.labels."helm.sh/chart"'

    # Keep your existing specific ignores
    resource.customizations.ignoreDifferences.external-secrets.io_ExternalSecret: |+
      jqPathExpressions:
      - '.spec.data[].remoteRef.conversionStrategy'
      - '.spec.data[].remoteRef.decodingStrategy'
      - '.spec.data[].remoteRef.metadataPolicy'

    # Single merged block (typo fixed: caBundle); no duplicate keys
    resource.customizations: |
      admissionregistration.k8s.io/MutatingWebhookConfiguration:
        ignoreDifferences: |
          jsonPointers:
          - /webhooks/0/clientConfig/caBundle
      argoproj.io/Application:
        health.lua: |
          hs = {}
          hs.status = "Progressing"
          hs.message = ""
          if obj.status ~= nil then
            if obj.status.health ~= nil then
              hs.status = obj.status.health.status
              if obj.status.health.message ~= nil then
                hs.message = obj.status.health.message
              end
            end
          end
          return hs
      external-secrets.io/ExternalSecret:
        ignoreDifferences: |
          jqPathExpressions:
            - .spec.data[].remoteRef.conversionStrategy
            - .spec.data[].remoteRef.decodingStrategy
            - .spec.data[].remoteRef.metadataPolicy

    kustomize.buildOptions: "--enable-helm"
    timeout.reconciliation.jitter: 60s
    timeout.reconciliation: 300s
    statusbadge.enabled: true

    # resource.ignoreResourceUpdatesEnabled: "true"

    resource.customizations.health.argoproj.io_Application: |
      hs = {}
      hs.status = "Progressing"
      hs.message = ""
      if obj.status ~= nil then
        if obj.status.health ~= nil then
          hs.status = obj.status.health.status
          if obj.status.health.message ~= nil then
            hs.message = obj.status.health.message
          end
        end
      end
      return hs

    oidc.config: |
      name: OIDC
      issuer: ${var.argocd_oidc_issuer_url}
      clientID: ${var.argocd_oidc_client_id}
      clientSecret: ${var.argocd_oidc_client_secret}
      enableUserInfoGroups: true
      userInfoCacheExpiration: "5m"
      userInfoPath: /userinfo
      requestedIDTokenClaims:
        email:
          essential: true
        groups:
          essential: true
      requestedScopes:
        - openid
        - profile
        - email
        - groups

  credentialTemplates:
    github-enterprise-creds-1:
      url: ${var.argocd_tamplate_repo_url}
      githubAppID: "${var.argocd_github_app_id}"
      githubAppInstallationID: "${var.argocd_github_app_installation_id}"
      githubAppPrivateKey: |
      ${indent(8, var.argocd_github_app_private_key)}
  params:
    controller.diff.server.side: true
    server.insecure: true
    otlp.address: ''
    ## Controller Properties
    controller.status.processors: 20
    controller.operation.processors: 10
    controller.self.heal.timeout.seconds: 5
    controller.repo.server.timeout.seconds: 60
  rbac:
    policy.default: role:admin
    policy.csv: |
      g, argocd:admin, role:admin
      g, argocd:read_all, role:readonly
      g, oidc-admins, role:admin
      g, oidc-readers, role:readonly
  secret:
    argocdServerAdminPassword: ${var.argocd_admin_password}

externalRedis:
  host: redis-cluster-redis-headless.kb-system.svc.cluster.local
  username: ""
  password: ""
  port: 6379
  existingSecret: redis-admin-secret
  secretAnnotations: {}

redis:
  enabled: false

controller:
  resources:
    requests:
      cpu: 100m
      memory: 700Mi
    limits:
      memory: 4Gi
  args:
    repoServerTimeoutSeconds: 300

dex:
  enabled: false

redis-ha:
  enabled: false
redis:
  resources:
    requests:
      cpu: 100m
      memory: 64Mi
    limits:
      memory: 1Gi

server:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      memory: 1Gi
  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 50
    targetMemoryUtilizationPercentage: 50
  ingress:
    enabled: true
    annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
        nginx.ingress.kubernetes.io/ssl-passthrough: "true"
        external-dns.alpha.kubernetes.io/enabled: "true"
        # nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
        # nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
        # nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
        # cert-manager.io/renew-before: "720h"
        # cert-manager.io/duration: "2160h"
    ingressClassName: nginx
    hostname: ${var.argocd_hostname}
    tls: true
    https: true

  server:
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        memory: 1Gi
    autoscaling:
      enabled: false
      minReplicas: 1
      maxReplicas: 5
      targetCPUUtilizationPercentage: 50
      targetMemoryUtilizationPercentage: 50
    ingress:
      enabled: true
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
        nginx.ingress.kubernetes.io/ssl-passthrough: "true"
        external-dns.alpha.kubernetes.io/enabled: "true"
        # nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
        # nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
        # nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
        # cert-manager.io/renew-before: "720h"
        # cert-manager.io/duration: "2160h"
      ingressClassName: nginx
      hostname: ${var.argocd_hostname}
      tls: true
      https: true
    metrics: &metrics
      enabled: true
      serviceMonitor:
        enabled: true
        additionalLabels:
          release: monitoring
repoServer:
  replicas: 2
  rbac:
  - verbs:
    - get
    - list
    - watch
    apiGroups:
    - ''
    resources:
    - secrets
    - configmaps
  automountServiceAccountToken: true
  volumes:
  - name: avp-cmp-plugin
    configMap:
      name: avp-cmp-plugin
  - name: custom-tools
    emptyDir: {}

  initContainers:
  - name: download-tools
    image: registry.access.redhat.com/ubi8
    command: [ sh, -c ]
    env:
    - name: AVP_VERSION
      value: "1.18.1"
    args:
    - >-
      curl -L https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v$(AVP_VERSION)/argocd-vault-plugin_$(AVP_VERSION)_linux_amd64 -o argocd-vault-plugin && chmod +x argocd-vault-plugin && mv argocd-vault-plugin /custom-tools/
    volumeMounts:
    - mountPath: /custom-tools
      name: custom-tools

  extraContainers:
  # argocd-vault-plugin with plain YAML
  - name: avp-k8s
    command:
    - "/var/run/argocd/argocd-cmp-server"
    image: quay.io/argoproj/argocd
    securityContext:
      runAsNonRoot: true
      runAsUser: 999
    volumeMounts:
    - mountPath: /var/run/argocd
      name: var-files
    - mountPath: /home/argocd/cmp-server/plugins
      name: plugins
    - mountPath: /tmp
      name: tmp

    - mountPath: /home/argocd/cmp-server/config/plugin.yaml
      subPath: avp-k8s.yaml
      name: avp-cmp-plugin

    - name: custom-tools
      subPath: argocd-vault-plugin
      mountPath: /usr/local/bin/argocd-vault-plugin
    envFrom:
    - secretRef:
        name: avp-plugin-credentials

  # argocd-vault-plugin with plain Kustomize
  - name: avp-kustomize
    command: [ /var/run/argocd/argocd-cmp-server ]
    image: quay.io/argoproj/argocd
    securityContext:
      runAsNonRoot: true
      runAsUser: 999
    volumeMounts:
    - mountPath: /var/run/argocd
      name: var-files
    - mountPath: /home/argocd/cmp-server/plugins
      name: plugins
    - mountPath: /tmp
      name: tmp

    - mountPath: /home/argocd/cmp-server/config/plugin.yaml
      subPath: avp-kustomize.yaml
      name: avp-cmp-plugin

    - name: custom-tools
      subPath: argocd-vault-plugin
      mountPath: /usr/local/bin/argocd-vault-plugin
    envFrom:
    - secretRef:
        name: avp-plugin-credentials
    # argocd-vault-plugin with Helm
  - name: avp-helm
    command: [ /var/run/argocd/argocd-cmp-server ]
    image: quay.io/argoproj/argocd
    securityContext:
      runAsNonRoot: true
      runAsUser: 999
    volumeMounts:
    - mountPath: /var/run/argocd
      name: var-files
    - mountPath: /home/argocd/cmp-server/plugins
      name: plugins
    - mountPath: /tmp
      name: tmp

    # Register plugins into sidecar
    - mountPath: /home/argocd/cmp-server/config/plugin.yaml
      subPath: avp-helm.yaml
      name: avp-cmp-plugin

    - name: custom-tools
      subPath: argocd-vault-plugin
      mountPath: /usr/local/bin/argocd-vault-plugin
    envFrom:
    - secretRef:
        name: avp-plugin-credentials

applicationSet:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      memory: 1Gi
  argocdUrl: ${var.argocd_hostname}
EOT


  cert_manager_values   = var.cert_manager_values != "" ? var.cert_manager_values : <<EOT
crds:
  enabled: true
  keep: true
extraArgs:
  - --feature-gates=ExperimentalGatewayAPISupport=true
clusterResourceNamespace: cert-manager
  EOT
  longhorn_values       = var.longhorn_values != "" ? var.longhorn_values : <<EOT
    defaultSettings:
      defaultDataPath: "/var/longhorn"
      # This tells Longhorn to use the 'longhorn' bucket of our S3.
      backupTarget: s3://longhorn@us-east-1/longhorn
      deletingConfirmationFlag: true
      # The secret where the MinIO credentials are stored.
      backupTargetCredentialSecret: minio-secret
      kubernetesClusterAutoscalerEnabled: true
    persistence:
        defaultClassReplicaCount: ${length(try(module.rke2_metalhost_servers.server_ips, []))}
        defaultClass: true
        # defaultFsType: ext4
    ingress:
        enabled: true
        ingressClassName: nginx
        host: longhorn.prod.techsecom.io

        tls: enabled
        tlsSecret: longhorn.local-tls

        annotations:
            cert-manager.io/cluster-issuer: letsencrypt-prod
            external-dns.alpha.kubernetes.io/enabled: "true"
  EOT
  csi-driver-nfs_values = var.csi-driver-nfs_values != "" ? var.csi-driver-nfs_values : <<EOT
    # kubeletDir: /opt/rke2/kubelet
    feature:
      enableFSGroupPolicy: true
      enableInlineVolume: true
      propagateHostMountOptions: false
    storageClass:
      create: true
      name: nfs-csi
      annotations:
        storageclass.kubernetes.io/is-default-class: "false"
      parameters:
        server: "${var.nfs_server_ip}"
        share: /var/nfs/shared/${var.nfs_shared_dir}
        subDir: ${var.csi_driver_nfs_subdir}
        mountPermissions: "0"
        #     csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
        # csi.storage.k8s.io/provisioner-secret-name: "mount-options"
        # csi.storage.k8s.io/provisioner-secret-namespace: "default"
      reclaimPolicy: Delete
      volumeBindingMode: WaitForFirstConsumer
      allowVolumeExpansion: true
      mountOptions:
      - nfsvers=${var.nfsver}
      # - tcp
      # - hard
      # - timeo=600
      # - retrans=2
      # - async
  EOT

  csi_driver_nfs_localpath_values = var.csi_driver_nfs_localpath_values != "" ? var.csi_driver_nfs_localpath_values : <<EOT
    replicaCount: 1
    storageClass:
      create: true
      defaultClass: false
      defaultVolumeType: hostPath
      name: nfs-local-path
      reclaimPolicy: Delete
      volumeBindingMode: WaitForFirstConsumer
      ## Set a path pattern, if unset the default will be used
      pathPattern: "{{ .PVC.Namespace }}/{{ .PVC.Name }}"
      volumeNamePattern: "{{ .PVC.Annotations.volumeName }}"
    nodePathMap: []
    sharedFileSystemPath: "${var.nfs_mount_point}"
  EOT

  rke2_custom_manifests_base = [
    "${path.module}/manifest/cilium.yaml",
    "${path.module}/manifest/coredns.yaml",
    "${path.module}/manifest/multus.yaml",
    "${path.module}/manifest/generic-device-plugin.yaml",
    "${path.module}/manifest/nodelocaldns.yaml",
    "${path.module}/manifest/configmap-dns-proxy.yaml",
    "${path.module}/manifest/prometheus-operator.yaml",
    "${path.module}/manifest/nvidia-kubevirt-gpu-device-plugin.yaml",
  ]
  extra_manifests_dir = coalesce(var.extra_manifests_dir, "${path.module}/manifest")
  rke2_custom_manifests = concat(
    local.rke2_custom_manifests_base,
    [for f in local_file.extra_manifest : f.filename],
  )
}
