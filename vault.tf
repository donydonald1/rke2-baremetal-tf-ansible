module "vault" {
  source        = "./modules/vault/"
  vault_secrets = var.vault_secrets
  depends_on    = [data.kubernetes_all_namespaces.all, module.kubeconfig, kubectl_manifest.vault]
}
