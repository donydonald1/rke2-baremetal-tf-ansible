resource "helm_release" "vault_operator" {
  chart            = "vault-operator"
  name             = "vault-operator"
  repository       = "oci://ghcr.io/bank-vaults/helm-charts"
  namespace        = "vault"
  create_namespace = true
  values           = ["${local.vault_values}"]

}


