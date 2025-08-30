resource "helm_release" "vault_operator" {
  chart            = "vault-operator"
  name             = "vault-operator"
  repository       = "oci://ghcr.io/bank-vaults/helm-charts"
  namespace        = "vault"
  create_namespace = true
  values           = ["${local.vault_values}"]
  depends_on       = [module.kubeconfig]
}

resource "helm_release" "cloudflared" {
  chart             = "app-template"
  name              = "cloudflared"
  dependency_update = true
  version           = "4.2.0"
  repository        = "https://bjw-s-labs.github.io/helm-charts"
  namespace         = kubernetes_namespace.this["cloudflared"].metadata[0].name
  create_namespace  = true
  values            = [local.cloudflared_values]
  depends_on        = [kubernetes_secret.cloudflared_credentials]
}

# resource "helm_release" "csi-driver-nfs" {
#   count            = var.enable_csi-driver-nfs ? 1 : 0
#   chart            = "csi-driver-nfs"
#   name             = "csi-driver-nfs"
#   repository       = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
#   namespace        = "csi-driver-nfs"
#   force_update     = false
#   create_namespace = true
#   values           = [local.csi-driver-nfs_values]
#   depends_on       = [module.kubeconfig, ]
# }
