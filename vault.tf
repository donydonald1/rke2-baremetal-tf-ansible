module "vault" {
  source        = "./modules/vault/"
  vault_secrets = var.vault_secrets
  depends_on    = [module.kubeconfig, kubectl_manifest.vault]
}
