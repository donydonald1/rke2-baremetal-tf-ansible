locals {
  vault_values = var.vault_operator_values != "" ? var.vault_operator_values : <<EOT
name: vault-operator
  EOT
}
