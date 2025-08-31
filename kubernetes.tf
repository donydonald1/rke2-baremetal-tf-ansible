module "k8s_infrastructure" {
  source = "./modules/kubernetes"

  cloudflared_namespace     = var.namespaces["cloudflared"]
  tunnel_id_random_password = module.cloudflare.tunnel_id_random_password
  tunnel_id                 = module.cloudflare.tunnel_id
  cluster_name              = module.cloudflare.cluster_name
  cloudflare_account_id     = module.cloudflare.cloudflare_account_id
  external_dns_namespace    = var.namespaces["external-dns"]
  cloudflare_api_token      = module.cloudflare.cloudflare_api_token
  cert_manager_issuer_token = module.cloudflare.cert_manager_issuer_token
  cert_manager_namespace    = var.namespaces["cert-manager"]
  depends_on                = [module.cloudflare, module.helm_config, module.kubeconfig]
}
