locals {
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
}
