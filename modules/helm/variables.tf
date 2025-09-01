variable "vault_operator_values" {
  description = "Values for the Vault Operator Helm chart"
  type        = string
  default     = ""
}

variable "cloudflared_namespace" {
  description = "Namespace for Cloudflared resources"
  type        = string
  default     = "cloudflare"
}

variable "cloudflared_values" {
  description = "Values for the Cloudflared Helm chart"
  type        = string
  default     = ""
}

variable "domain" {
  description = "The domain for the Cloudflare tunnel"
  type        = string
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string

}
