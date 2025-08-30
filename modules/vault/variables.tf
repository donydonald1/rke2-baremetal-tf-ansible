variable "vault_secrets" {
  type = map(object({
    path = string
    data = map(string)
  }))
  description = "Map of vault secrets to manage."
  default = {
  }
}
