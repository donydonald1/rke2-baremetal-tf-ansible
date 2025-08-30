output "cloudflare_api_token" {
  value       = cloudflare_api_token.external_dns.value
  sensitive   = true
  description = "Cloudflare API token"
}

output "tunnel_id" {
  value       = cloudflare_tunnel.homelab.id
  description = "Cloudflare Tunnel ID"
}

output "tunnel_id_random_password" {
  value       = random_password.tunnel_secret.result
  description = "Random password for Cloudflare Tunnel"
}

output "cert_manager_issuer_token" {
  value       = cloudflare_api_token.cert_manager.value
  sensitive   = true
  description = "Cloudflare API token for cert-manager"
}
