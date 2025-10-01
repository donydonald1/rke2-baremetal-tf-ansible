resource "helm_release" "vault_operator" {
  chart            = "vault-operator"
  name             = "vault-operator"
  repository       = "oci://ghcr.io/bank-vaults/helm-charts"
  namespace        = "vault"
  create_namespace = true
  values           = ["${local.vault_values}"]

}

resource "helm_release" "nginx" {
  name             = "nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.13.2"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = false
  values           = [local.nginx_values]
}

resource "helm_release" "metallb" {
  count            = var.enable_metallb ? 1 : 0
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = var.metallb_chart_version != "" ? var.metallb_chart_version : "0.15.2"
  namespace        = var.metallb_namespace != "" ? var.metallb_namespace : "metallb-system"
  create_namespace = true
  wait             = false
  values           = [local.metallb_values]

}
