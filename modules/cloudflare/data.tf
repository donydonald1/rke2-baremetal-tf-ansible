data "cloudflare_zone" "zone" {
  name = var.cloudflare_zone
}

data "cloudflare_api_token_permission_groups" "all" {}
