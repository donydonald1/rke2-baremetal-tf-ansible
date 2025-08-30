terraform {
  # required_version = ">= 1.1.0"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }


    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.0"
    }


    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

}
