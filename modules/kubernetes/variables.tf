variable "cloudflared_namespace" {
  description = "The namespace for the Cloudflared deployment"
  type        = string
  default     = "cloudflare"
}

variable "tunnel_id_random_password" {
  description = "The random password for the tunnel ID"
  type        = string
}

variable "tunnel_id" {
  description = "The ID of the tunnel"
  type        = string
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string
}

variable "cloudflare_account_id" {
  description = "The Cloudflare account ID"
  type        = string
}

variable "external_dns_namespace" {
  description = "The namespace for the External DNS deployment"
  type        = string
  default     = "external-dns"
}

variable "cloudflare_api_token" {
  description = "The Cloudflare API token for External DNS"
  type        = string
}

variable "cert_manager_namespace" {
  description = "The namespace for the Cert-Manager deployment"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_issuer_token" {
  description = "The Cloudflare API token for Cert-Manager"
  type        = string
}
