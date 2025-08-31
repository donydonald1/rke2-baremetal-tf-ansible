resource "helm_release" "vault_operator" {
  chart            = "vault-operator"
  name             = "vault-operator"
  repository       = "oci://ghcr.io/bank-vaults/helm-charts"
  namespace        = "vault"
  create_namespace = true
  values           = ["${var.vault_operator_values}"]

}

resource "helm_release" "cloudflared" {
  chart             = "app-template"
  name              = "cloudflared"
  dependency_update = true
  version           = "4.2.0"
  repository        = "https://bjw-s-labs.github.io/helm-charts"
  namespace         = var.cloudflared_namespace
  create_namespace  = true
  values            = [var.cloudflared_values]
}
