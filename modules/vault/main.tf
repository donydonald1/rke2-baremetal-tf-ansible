# write secrets to vault
resource "vault_generic_secret" "add_secrets_to_vault" {
  for_each = var.vault_secrets

  path                = each.value.path
  delete_all_versions = true

  data_json = jsonencode(each.value.data)
}
