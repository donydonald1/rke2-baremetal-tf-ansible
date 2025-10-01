variable "vault_operator_values" {
  description = "Values for the Vault Operator Helm chart"
  type        = string
  default     = ""
}

variable "nginx_service_loadbalancer_ip" {
  description = "The IP address of the loadbalancer ip."
  type        = string
  default     = ""
}

variable "nginx_client_max_body_size" {
  description = "The maximum body size for nginx."
  type        = string
  default     = "10M"
}

variable "nginx_client_body_buffer_size" {
  description = "The client body buffer size for nginx."
  type        = string
  default     = "10M"
}

variable "wireguard_port" {
  description = "The port for the wireguard"
  type        = number
  default     = 51820
}

variable "nginx_values" {
  description = "Values for the NGINX Helm chart"
  type        = string
  default     = ""
}

variable "kube-vip-nginx-lb-ip" {
  description = "The IP address for the kube-vip nginx loadbalancer."
  type        = string
  default     = ""
}

variable "enable_kube-vip-lb" {
  description = "Whether to enable kube-vip load balancer"
  type        = bool
  default     = false
  validation {
    condition = (
      !var.enable_kube-vip-lb || (
        var.kube-vip-nginx-lb-ip != null && var.kube-vip-nginx-lb-ip != ""
      )
    )
    error_message = "If enable_kube-vip-lb is true, kube-vip-nginx-lb-ip must be provided and cannot be empty."
  }
}

variable "enable_nginx_service_monitor" {
  description = "Whether to enable the nginx service monitor"
  type        = bool
  default     = false
}

variable "enable_metallb" {
  description = "Whether to enable the MetalLB Helm chart"
  type        = bool
  default     = false
}

variable "metallb_chart_version" {
  description = "The version of the MetalLB Helm chart to use"
  type        = string
  default     = ""
}

variable "metallb_values" {
  description = "Values for the MetalLB Helm chart"
  type        = string
  default     = ""
}

variable "metallb_namespace" {
  description = "The namespace for the MetalLB Helm chart"
  type        = string
  default     = "metallb-system"
}

variable "prometheus_service_account_name" {
  description = "The service account name for Prometheus to use in MetalLB"
  type        = string
  default     = "kube-prometheus-stack-prometheus"
}

variable "prometheus_service_monitor_namespace" {
  description = "The namespace for the Prometheus ServiceMonitor"
  type        = string
  default     = "monitoring"
}

variable "enable_metallb_prometheusrule" {
  description = "Whether to enable the MetalLB PrometheusRule"
  type        = bool
  default     = false
}

variable "enable_metallb_podmonitor" {
  description = "Whether to enable the MetalLB PodMonitor"
  type        = bool
  default     = false
}

variable "prometheus_namespace" {
  description = "The namespace where Prometheus is deployed"
  type        = string
  default     = "monitoring"
}

variable "ingress_lb_ip" {
  description = "The IP address for the ingress loadbalancer."
  type        = string
  default     = ""
}
