# module "helm_config" {
#   source                = "./modules/helm"
#   vault_operator_values = local.vault_values
#   cloudflared_values    = local.cloudflared_values
#   cloudflared_namespace = var.cloudflare_namespace["cloudflared"]
#   depends_on            = [null_resource.kustomization]
# }
# # 
