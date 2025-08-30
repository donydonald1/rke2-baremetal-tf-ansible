terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "~> 5.1"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    github = {
      source = "integrations/github"
      version = "~> 6.3"
    }
  }
}
