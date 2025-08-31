# data "kubernetes_all_namespaces" "all" {
#   depends_on = [module.kubeconfig]
# }

# data "kubernetes_secret_v1" "vault_seal" {
#   # count = var.enable_vault ? 1 : 0

#   metadata {
#     name      = "vault-unseal-keys"
#     namespace = "vault"
#   }

#   depends_on = [time_sleep.sleep-wait-vault]
# }
