# terraform {
#   # required_version = ">= 1.1.0"
#   required_providers {
#     vault = {
#       source  = "hashicorp/vault"
#       version = "~> 4.4"
#     }

#   }
# }

# provider "vault" {
#   address         = "https://${var.vault_hostname}"
#   skip_tls_verify = true
#   # token           = module.manager.vault_root_token
#   auth_login_userpass {
#     username = "admin"
#     password = "Techsecoms-@rke2"

#   }
#   max_retries     = 5
#   # alias           = "vault"

# }

