data "kubernetes_secret_v1" "vault_seal" {
  # count = var.enable_vault ? 1 : 0

  metadata {
    name      = "vault-unseal-keys"
    namespace = var.vault_namespace
  }

  depends_on = [time_sleep.sleep-wait-vault]
}

# data "kubernetes_namespace" "ns" {
#   for_each = toset(var.namespaces)
#   metadata {
#     name = each.key
#   }
# }
