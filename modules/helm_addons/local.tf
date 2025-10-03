locals {
  vault_values = var.vault_operator_values != "" ? var.vault_operator_values : <<EOT
name: vault-operator
  EOT
  nginx_values = var.nginx_values != "" ? var.nginx_values : <<EOT
controller:
  kind: Deployment
  service:
    type: LoadBalancer
    loadBalancerIP: "${var.ingress_lb_ip}"
    externalTrafficPolicy: Local
    enableHttp: true
    enableHttps: true
    ports:
      http: 80
      https: 443

    targetPorts:
      http: http
      https: https
  replicaCount: 3
  allowSnippetAnnotations: true
  addHeaders:
    Referrer-Policy: strict-origin-when-cross-origin
  config:
    annotation-value-word-blocklist: "load_module,lua_package,_by_lua,location,root,proxy_pass,serviceaccount,{,},',\""
    hsts: "true"
    hsts-include-subdomains: "false"
    hsts-max-age: "63072000"
    server-name-hash-bucket-size: "256"
    client-body-buffer-size: "${var.nginx_client_body_buffer_size}"
    client-max-body-size: "${var.nginx_client_max_body_size}"
    use-http2: "true"
    ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4"
    ssl-protocols: "TLSv1.3 TLSv1.2"
    server-tokens: "false"
    # Configure smaller defaults for upstream-keepalive-*, see https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration
    upstream-keepalive-connections: 100 # Limit of 100 held-open connections
    upstream-keepalive-time:        30s # 30 second limit for connection reuse
    upstream-keepalive-timeout:       5 # 5 second timeout to hold open idle connections
    upstream-keepalive-requests:   1000 # 1000 requests per connection, before recycling
    enable-brotli: "true"
    brotli-level: "6"
    brotli-types: "text/xml image/svg+xml application/x-font-ttf image/vnd.microsoft.icon application/x-font-opentype application/json font/eot application/vnd.ms-fontobject application/javascript font/otf application/xml application/xhtml+xml text/javascript application/x-javascript text/plain application/x-font-truetype application/xml+rss image/x-icon font/opentype text/css image/x-win-bitmap"
    enable-real-ip: "true"
    ignore-invalid-headers: "false"
    use-forwarded-headers: true
    allow-snippet-annotations: true
    annotations-risk-level: Critical
  ingressClass: nginx
  ingressClassResource:
    name: nginx
    enabled: true
    default: true
    # controllerValue: "k8s.io/ingress-nginx"
  podAnnotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "10254"
    co.elastic.logs/enabled: "true"
  metrics:
    enabled: true
    serviceMonitor:
      enabled: ${var.enable_nginx_service_monitor ? "true" : "false"}
      additionalLabels:
        release: kube-prometheus-stack
scope:
  enabled: true
tcp:
  22: "gitlab/gitlab-gitlab-shell:22"
udp:
  ${var.wireguard_port}: "vpn/wireguard:${var.wireguard_port}"

  EOT

  metallb_values = var.metallb_values != "" ? var.metallb_values : <<EOT
    crds:
      enabled: true
    prometheus:
      serviceAccount: ${var.prometheus_service_account_name != "" ? var.prometheus_service_account_name : "kube-prometheus-stack-prometheus"}
      namespace: ${var.prometheus_namespace != "" ? var.prometheus_namespace : "monitoring"}
      podMonitor:
        enabled: ${var.enable_metallb_podmonitor ? "true" : "false"}
      prometheusRule:
        enabled: ${var.enable_metallb_prometheusrule ? "true" : "false"}
    speaker:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          memory: 512Mi
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
  EOT
}
