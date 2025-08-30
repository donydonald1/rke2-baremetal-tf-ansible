locals {
  ssh_agent_identity  = var.ssh_private_key == null ? var.ssh_public_key : null
  ansible_hosts_group = var.ansible_hosts_group != "" ? var.ansible_hosts_group : "all"
  all_sans = concat(
    flatten([module.manager.guest_ips]),
    flatten([module.manager.vm_names]),
    flatten([var.manager_rke2_api_dns]),
    flatten([var.manager_rke2_api_ip]),
    flatten(var.additional_sans)
  )

  rke2_registries_update_script = <<EOF
DATE=`date +%Y-%m-%d_%H-%M-%S`
if cmp -s /root/registries.yaml /etc/rancher/rke2/registries.yaml; then
  echo "No update required to the registries.yaml file"
else
  echo "Backing up /etc/rancher/rke2/registries.yaml to /root/registries_$DATE.yaml"
  cp /etc/rancher/rke2/registries.yaml /root/registries_$DATE.yaml
  echo "Updated registries.yaml detected, restart of rke2 service required"
  cp /root/registries.yaml /etc/rancher/rke2/registries.yaml
  if systemctl is-active --quiet rke2-server; then
    systemctl restart rke2-server || (echo "Error: Failed to restart rke2-server. Restoring /etc/rancher/rke2/registries.yaml from backup" && cp /root/registries_$DATE.yaml /etc/rancher/rke2/registries.yaml && systemctl restart rke2-server)
  elif systemctl is-active --quiet rke2-agent; then
    systemctl restart rke2-agent || (echo "Error: Failed to restart rke2-agent. Restoring /etc/rancher/rke2/registries.yaml from backup" && cp /root/registries_$DATE.yaml /etc/rancher/rke2/registries.yaml && systemctl restart rke2-agent)
  else
    echo "No active rke2-server or rke2-agent service found"
  fi
  echo "rke2 service or rke2-agent service restarted successfully"
fi
  EOF

  rke2_config_update_script = <<EOF
DATE=`date +%Y-%m-%d_%H-%M-%S`
if cmp -s /root/config.yaml /etc/rancher/rke2/config.yaml; then
  echo "No update required to the config.yaml file"
else
  if [ -f "/etc/rancher/rke2/config.yaml" ]; then
    echo "Backing up /etc/rancher/rke2/config.yaml to /root/config_$DATE.yaml"
    cp /etc/rancher/rke2/config.yaml /root/config_$DATE.yaml
  fi
  echo "Updated config.yaml detected, restart of rke2 service required"
  cp /root/config.yaml /etc/rancher/rke2/config.yaml
  if systemctl is-active --quiet rke2-server; then
    systemctl restart rke2-server || (echo "Error: Failed to restart rke2-server. Restoring /etc/rancher/rke2/config.yaml from backup" && cp /root/config_$DATE.yaml /etc/rancher/rke2/config.yaml && systemctl restart rke2-server)
  elif systemctl is-active --quiet rke2-agent; then
    systemctl restart rke2-agent || (echo "Error: Failed to restart rke2-agent. Restoring /etc/rancher/rke2/config.yaml from backup" && cp /root/config_$DATE.yaml /etc/rancher/rke2/config.yaml && systemctl restart rke2-agent)
  else
    echo "No active rke2-server or rke2-agent service found"
  fi
  echo "rke2 service or rke2-agent service (re)started successfully"
fi
  EOF


  kustomization_backup_yaml = yamlencode({
    apiVersion = "kustomize.config.k8s.io/v1beta1"
    kind       = "Kustomization"
    resources = concat(
      [
        "https://github.com/rancher/system-upgrade-controller/releases/download/${var.sys_upgrade_controller_version}/system-upgrade-controller.yaml",
        "https://github.com/rancher/system-upgrade-controller/releases/download/${var.sys_upgrade_controller_version}/crd.yaml"
      ],
      var.enable_cert_manager || var.enable_rancher ? ["cert_manager.yaml"] : [],
      var.enable_vault ? ["vault.yaml"] : [],
      var.enable_argocd ? ["argocd.yaml"] : [],
      # var.enable_metallb ? ["metallb.yaml"] : [],
      var.enable_external_dns ? ["external-dns.yaml"] : [],
      var.enable_external_secrets ? ["external-secrets.yaml"] : [],
      var.rancher_registration_manifest_url != "" ? [var.rancher_registration_manifest_url] : [],
      var.enable_rancher ? ["rancher.yaml"] : [],
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

  cert_manager_values = var.cert_manager_values != "" ? var.cert_manager_values : <<EOT
crds:
  enabled: true
  keep: true
extraArgs:
  - --feature-gates=ExperimentalGatewayAPISupport=true
clusterResourceNamespace: cert-manager
  EOT

  argocd_values   = var.argocd_values != "" ? var.argocd_values : <<EOT
---
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
    # application.resourceTrackingMethod: annotation+label
    admin.enabled: true
    exec.enabled: true
    url: https://${var.argocd_hostname}
    resource.compareoptions: |
      # if ignoreAggregatedRoles set to true then differences caused by aggregated roles in RBAC resources are ignored.
      ignoreAggregatedRoles: true

    resource.customizations.ignoreDifferences.all: |+
      jqPathExpressions:
      - '.metadata.labels."helm.sh/chart"'
    resource.customizations.ignoreDifferences.external-secrets.io_ExternalSecret:
      |+
      jqPathExpressions:
      - '.spec.data[].remoteRef.conversionStrategy'
      - '.spec.data[].remoteRef.decodingStrategy'
      - '.spec.data[].remoteRef.metadataPolicy'
    resource.customizations: |
      admissionregistration.k8s.io/MutatingWebhookConfiguration:
        ignoreDifferences: |
          jsonPointers:
          - /webhooks/0/clientConfig/caBundl
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
      issuer: ${var.argocd_iodc_issuer_url}
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
  cmp:
    create: true
    plugins:
      kustomize-build-with-helm:
        generate:
          command: [ sh, -c ]
          args: [ kustomize build --enable-helm ]
      helmwave-plugin:
        generate:
          command: [ "/bin/ash", "-c" ]
          args:
            - |
              helmwave build &> /tmp/log.txt && find .helmwave/manifest -type f | xargs cat
        discover:
          fileName: "./helmwave.yml*"
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
    policy.csv: |
      g, argocd:admin, role:admin
      g, argocd:read_all, role:readonly
  secret:
    argocdServerAdminPassword: ${var.argocd_admin_password}
    
crds:
  install: true
  keep: false

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
  enabled: true
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

repoServer:
  containerSecurityContext:
    readOnlyRootFilesystem: true
  replicas: 2
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      memory: 2Gi
  initContainers:
    - name: download-tools
      image: registry.access.redhat.com/ubi8
      env:
        - name: AVP_VERSION
          value: 1.18.1
      command: [sh, -c]
      args:
        - >-
          curl -L https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v$(AVP_VERSION)/argocd-vault-plugin_$(AVP_VERSION)_linux_$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) -o argocd-vault-plugin &&
          chmod +x argocd-vault-plugin &&
          mv argocd-vault-plugin /custom-tools/
      volumeMounts:
        - mountPath: /custom-tools
          name: custom-tools
  extraContainers:
    - name: kustomize-build-with-helm
      command:
        - argocd-cmp-server
      image: '{{ default .Values.global.image.repository .Values.repoServer.image.repository }}:{{ default (include "argo-cd.defaultTag" .) .Values.repoServer.image.tag }}'
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        seccompProfile:
          type: RuntimeDefault
        capabilities:
          drop: [ ALL ]
      volumeMounts:
        - name: plugins
          mountPath: /home/argocd/cmp-server/plugins
        - name: cmp-kustomize-build-with-helm
          mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: kustomize-build-with-helm.yaml
        - mountPath: /tmp
          name: cmp-tmp
    - name: helmwave-plugin
      command: [ /var/run/argocd/argocd-cmp-server ]
      args: [ --loglevel, debug ]
      image: ghcr.io/helmwave/helmwave:0.36.4
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      env:
        - name: HELM_CONFIG_HOME
          value: ./helm-config
        - name: HELM_CACHE_HOME
          value: ./helm-cache
        - name: HELM_DATA_HOME
          value: ./helm-data
        - name: HELMWAVE_DIFF_MODE
          value: none

      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: helmwave-plugin.yaml
          name: argocd-cmp-cm
        - mountPath: /tmp
          name: cmp-tmp
    - name: lovely-plugin
      image: ghcr.io/crumbhole/lovely:1.2.0
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /tmp
          name: lovely-tmp
    - name: plugin-avp-directory-include
      command: [/var/run/argocd/argocd-cmp-server]
      image: "{{ default .Values.global.image.repository .Values.server.image.repository }}:{{ default (include \"argo-cd.defaultTag\" .) .Values.server.image.tag }}"
      env:
        - name: AVP_TYPE
          value: kubernetessecret
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /tmp
          name: cmp-tmp
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: avp-directory-include.yaml
          name: cmp-plugin
        - name: custom-tools
          subPath: argocd-vault-plugin
          mountPath: /usr/local/bin/argocd-vault-plugin
    - name: plugin-kustomize-inline
      command: [/var/run/argocd/argocd-cmp-server]
      image: "{{ default .Values.global.image.repository .Values.server.image.repository }}:{{ default (include \"argo-cd.defaultTag\" .) .Values.server.image.tag }}"
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /tmp
          name: cmp-tmp
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: kustomize-inline.yaml
          name: cmp-plugin
  volumes:
    - emptyDir: {}
      name: lovely-tmp
    - name: cmp-plugin
      configMap:
        name: cmp-plugin
    - name: custom-tools
      emptyDir: {}
    - name: cmp-tmp
      emptyDir: {}
    - name: cmp-kustomize-build-with-helm
      configMap:
        name: argocd-cmp-cm
    - configMap:
        name: argocd-cmp-cm
      name: argocd-cmp-cm
  rbac:
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["get", "watch", "list"]
  deploymentAnnotations:
    reloader.stakater.com/auto: "true"

extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cmp-plugin
      namespace: "{{ .Release.Namespace }}"
    data:
      avp-directory-include.yaml: |
        apiVersion: argoproj.io/v1alpha1
        kind: ConfigManagementPlugin
        metadata:
          name: avp-directory-include
        spec:
          allowConcurrency: true
          generate:
            command:
              - bash
              - "-c"
              - |
                argocd-vault-plugin generate $ARGOCD_ENV_FILE_NAME
          lockRepo: false
      kustomize-inline.yaml: |
        apiVersion: argoproj.io/v1alpha1
        kind: ConfigManagementPlugin
        metadata:
          name: kustomize-inline
        spec:
          allowConcurrency: true
          generate:
            command:
              - /bin/sh
              - -c
            args:
              - |
                echo "$ARGOCD_ENV_KUSTOMIZATION_YAML" > kustomization.yaml;
                kustomize build
          lockRepo: false


applicationSet:
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      memory: 1Gi


notifications:
  # -- Argo CD dashboard url; used in place of {{.context.argocdUrl}} in templates
  updateStrategy:
    type: Recreate

  secret:
    create: false

  metrics:
    enabled: false

  notifiers:
    service.alertmanager: |
      targets:
      - alertmanager-operated.monitoring.svc:9093

  resources:
    requests:
      cpu: 10m
      memory: 24Mi
    limits:
      memory: 128Mi

  subscriptions:
    - recipients:
        - alertmanager
      triggers:
        - on-health-degraded
        - on-sync-failed

  templates:
    template.app-deployed: |
      message: |
        *🚀{{.app.metadata.name}}*
        _Application {{.app.metadata.name}} is now running new version of deployments manifests_
      alertmanager:
        labels:
          severity: warning
          service: argocd
        annotations:
          message: |
            Application {{.app.metadata.name}} is now running new version of deployments manifests
    template.app-health-degraded: |
      message: |
        *💔{{.app.metadata.name}}*
        _Application {{.app.metadata.name}} has degraded._
        [Application details]({{.context.argocdUrl}}/applications/{{.app.metadata.name}})
      alertmanager:
        labels:
          severity: warning
          service: argocd
        annotations:
          message: |
            Application {{.app.metadata.name}} has degraded
    template.app-sync-failed: |
      message: |
        *❌{{.app.metadata.name}}*
        _The sync operation of application {{.app.metadata.name}} has failed at {{.app.status.operationState.finishedAt}} with the following error: {{.app.status.operationState.message}}_
        [Sync operation details]({{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true)
      alertmanager:
        labels:
          severity: warning
          service: argocd
        annotations:
          message: |
            The sync operation of application {{.app.metadata.name}} has failed at {{.app.status.operationState.finishedAt}} with the following error: {{.app.status.operationState.message}}

    # template.app-sync-running: |
    #   message: |
    #     The sync operation of application {{.app.metadata.name}} has started at {{.app.status.operationState.startedAt}}.
    #     Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .
    # template.app-sync-status-unknown: |
    #   message: |
    #     {{if eq .serviceType "slack"}}:exclamation:{{end}} Application {{.app.metadata.name}} sync is 'Unknown'.
    #     Application details: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}.
    #     {{if ne .serviceType "slack"}}
    #     {{range $c := .app.status.conditions}}
    #         * {{$c.message}}
    #     {{end}}
    #     {{end}}
    # template.app-sync-succeeded: |
    #   message: |
    #     {{if eq .serviceType "slack"}}:white_check_mark:{{end}} Application {{.app.metadata.name}} has been successfully synced at {{.app.status.operationState.finishedAt}}.
    #     Sync operation details are available at: {{.context.argocdUrl}}/applications/{{.app.metadata.name}}?operation=true .

  triggers:
    trigger.on-deployed: |
      - description: Application is synced and healthy. Triggered once per commit.
        oncePer: app.status.sync.revision
        send:
        - app-deployed
        when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
    trigger.on-health-degraded: |
      - description: Application has degraded
        send:
        - app-health-degraded
        when: app.status.health.status == 'Degraded' and app.metadata.name != 'root'
    trigger.on-sync-failed: |
      - description: Application syncing has failed
        send:
        - app-sync-failed
        when: app.status.operationState.phase in ['Error', 'Failed']
  argocdUrl: ${var.argocd_hostname}
  extraEnv:
    - name: TZ
      value: America/Chicago
  EOT
  rke2_registries = var.private_registries != "" ? var.private_registries : <<EOT
configs:
  ${var.private_registry_url}:
    auth:
      username: ${var.private_registry_username}
      password: ${var.private_registry_password}
    tls:
      insecure_skip_verify: ${var.private_registry_insecure_skip_verify}
  # docker.io:
  #   auth:
  #     username: ${var.dockerhub_registry_auth_username}
  #     password: ${var.dockerhub_registry_auth_password}
mirrors:
  ${var.private_registry_url}:
    endpoint:
      - http://${var.private_registry_url}
  # docker.io:
  #   endpoint:
  #     - https://docker.io
  EOT
  vault_values    = var.vault_values != "" ? var.vault_values : <<EOT
tlsDisable: true
server:
  affinity: ""
  dataStorage:
    storageClass: ${var.vault_storage_class}
  logFormat: json
  enabled: true
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
        nginx.ingress.kubernetes.io/ssl-passthrough: "false"
        external-dns.alpha.kubernetes.io/enabled: "true"
        # nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
        # nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    hosts:
      - host: ${var.vault_hostname}
    tls:
      - hosts:
          - ${var.vault_hostname}
        secretName: secret-ingress-tls
  ha:
    enabled: true
    setNodeId: true
    replicas: 3
    raft:
      enabled: true
      config: |
        ui = true
        plugin_directory = "/usr/local/libexec/vault"
        disable_mlock = true
        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          # Enable unauthenticated metrics access (necessary for Prometheus Operator)
          telemetry {
            unauthenticated_metrics_access = "true"
          }
        }
        storage "raft" {
          path = "/vault/data"
          retry_join {
            auto_join = "provider=k8s label_selector=\"app.kubernetes.io/name=vault,component=server\" namespace=\"{{ .Release.Namespace }}\""
            auto_join_scheme = "http"
            auto_join_port = 8200
          }
        }

        service_registration "kubernetes" {}
        telemetry {
          prometheus_retention_time = "30s"
          disable_hostname = true
        }
  extraContainers:
    - name: vault-unseal
      image: ghcr.io/bank-vaults/bank-vaults
      env:
        - name: VAULT_ADDR
          value: http://127.0.0.1:8200
      args:
        - unseal
        - --mode
        - k8s
        - --k8s-secret-name
        - vault-seal
        - --k8s-secret-namespace
        - vault
        - --raft-ha-storage
        - --raft-leader-address
        - "http://vault-active:8200"
csi:
  enabled: false
injector:
  enabled: false
  EOT
  rancher_values  = var.rancher_values != "" ? var.rancher_values : <<EOT
ingress:
  enabled: true
  ingressClassName: "${var.ingress_class}"
  extraAnnotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    external-dns.alpha.kubernetes.io/enabled: "true"
  hosts:
    - host: "${var.rancher_hostname != "" ? var.rancher_hostname : var.rancher_values}"
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    source: "secret"
    secretName: tls-rancher-ingress
hostname: "${var.rancher_hostname != "" ? var.rancher_hostname : var.rancher_values}"
replicas: ${length(var.baremetal_servers) > 1 ? 3 : 1}
bootstrapPassword: "${length(var.rancher_bootstrap_password) == 0 ? resource.random_password.rancher_bootstrap[0].result : var.rancher_bootstrap_password}"
global:
  cattle:
    psp:
      enabled: false
useBundledSystemChart: true
# letsEncrypt:
#   email: "donydnald1@icloud.com"
#   environment: production
#   ingress:
#     class: nginx
# privateCA: true
tls: ingress
agentTLSMode: system-store

agentTLSMode: system-store
  EOT

  external_secrets_values = var.external_secrets_values != "" ? var.external_secrets_values : <<EOT

  EOT
  external_dns_values     = var.external_dns_values != "" ? var.external_dns_values : <<EOT
# image:
#   registry: docker.io
#   repository: bitnami/external-dns
#   tag: 0.15.0-debian-12-r4
sources:
  - service
  - ingress
# provider: cloudflare
# txtOwnerId: ${var.cluster_name}
# extraArgs:
#   - --annotation-filter=external-dns.alpha.kubernetes.io/exclude notin (true)
# cloudflare:
#     apiKey: "${var.cloudflare_api_key}"
#     email: "${var.cloudflare_email}"
#     proxied: false
# interval: "1m"
# extraArgs:
#   annotation-filter:
#     - external-dns.alpha.kubernetes.io/exclude notin (true)
# triggerLoopOnEvent: true
policy: sync
provider: cloudflare
txtOwnerId: ${var.cluster_name}
env:
  - name: CF_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: cloudflare-api-token
        key: value
extraArgs:
  - --annotation-filter=external-dns.alpha.kubernetes.io/exclude notin (true)
  # - --default-targets=my-tunnel-guid-here.cfargotunnel.com
interval: 5m
triggerLoopOnEvent: true
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
  EOT

}
