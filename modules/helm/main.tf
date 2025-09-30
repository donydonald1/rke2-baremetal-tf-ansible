resource "helm_release" "vault_operator" {
  chart            = "vault-operator"
  name             = "vault-operator"
  repository       = "oci://ghcr.io/bank-vaults/helm-charts"
  namespace        = "vault"
  create_namespace = true
  values           = ["${local.vault_values}"]

}

resource "helm_release" "nginx" {
  # depends_on = [
  #   kubernetes_namespace.nginx,
  # ]

  name             = "nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.13.2"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = false
  timeout          = 600
  atomic           = true

  values = [local.nginx_values]

}
