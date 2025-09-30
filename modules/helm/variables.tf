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
