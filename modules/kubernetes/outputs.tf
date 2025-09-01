output "vault_root_token" {
  value       = length(data.kubernetes_secret_v1.vault_seal) > 0 ? lookup(data.kubernetes_secret_v1.vault_seal.data, "vault-root", null) : null
  sensitive   = true
  description = "The root token for Vault"
}
