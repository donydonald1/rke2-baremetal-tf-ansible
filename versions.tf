terraform {
  # required_version = ">= 1.1.0"
  required_providers {

    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
    assert = {
      source  = "hashicorp/assert"
      version = ">= 0.16.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 5.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

}
