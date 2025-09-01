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

variable "argocd_projects" {
  description = "A list of ArgoCD projects"
  type        = list(string)
  default     = ["system", "platform", "infrastructure", "monitoring", "main"]
}

variable "vault_wait_time" {
  description = "The time to wait for Vault to become ready"
  type        = string
  default     = "100s"
}

variable "vault_hostname" {
  description = "The hostname of the Vault server"
  type        = string
}

variable "vault_admin_username" {
  description = "The username for the Vault admin"
  type        = string
}

variable "vault_admin_password" {
  description = "The password for the Vault admin"
  type        = string
}

variable "domain" {
  description = "The domain for the Cloudflare tunnel"
  type        = string
}

variable "vault_oidc_discovery_url" {
  type        = string
  default     = ""
  description = "The OIDC discovery URL for the Vault OIDC configuration."
  sensitive   = true
}

variable "vault_oidc_client_id" {
  type        = string
  default     = ""
  description = "The Vault OIDC client ID."
  sensitive   = true
}

variable "vault_oidc_client_secret" {
  type        = string
  default     = ""
  description = "The Vault OIDC client secret."
  sensitive   = true
}

variable "vault_namespace" {
  description = "The namespace for the Vault deployment"
  type        = string
  default     = "vault"
}
