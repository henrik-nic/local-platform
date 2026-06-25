terraform {
  required_version = ">= 1.5.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

module "local_platform" {
  source = "../../modules/local_platform"

  cluster_name   = var.cluster_name
  server_count   = var.server_count
  agent_count    = var.agent_count
  namespaces     = var.namespaces
  app_namespaces = var.app_namespaces
  base_domain    = var.base_domain
  argocd_host    = var.argocd_host
  argocd_tls_secret_name = var.argocd_tls_secret_name
  metallb_version        = var.metallb_version
  metallb_ip_range       = var.metallb_ip_range
}
