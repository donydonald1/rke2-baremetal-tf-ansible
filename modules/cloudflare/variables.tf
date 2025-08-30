variable "cloudflare_zone" {
  type        = string
  default     = "techsecom.io"
  description = "The Cloudflare zone name."
}

variable "cloudflare_account_id" {
  type        = string
  default     = ""
  description = "The Cloudflare account ID."
}

variable "cloudflare_tunnel_name" {
  type        = string
  default     = "homelab"
  description = "The name of the Cloudflare tunnel."
}
