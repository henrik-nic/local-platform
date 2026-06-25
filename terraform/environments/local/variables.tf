variable "cluster_name" {
  type        = string
  description = "Name of the local k3d cluster."
  default     = "local"
}

variable "namespaces" {
  type        = list(string)
  description = "Namespaces to create in the local cluster."
  default = [
    "argocd",
    "local-dev",
    "local-test",
    "local-staging",
    "local-prod-sim",
  ]
}

variable "app_namespaces" {
  type        = list(string)
  description = "Namespaces that represent deployable application environments."
  default = [
    "local-dev",
    "local-test",
    "local-staging",
    "local-prod-sim",
  ]
}

variable "base_domain" {
  type        = string
  description = "Base domain used for local ingress hostnames."
  default     = "localtest.me"
}

variable "argocd_host" {
  type        = string
  description = "Hostname used to reach the Argo CD UI through ingress."
  default     = "argocd.localtest.me"
}

variable "argocd_tls_secret_name" {
  type        = string
  description = "TLS secret name used by the Argo CD ingress."
  default     = "argocd-server-tls"
}

variable "metallb_version" {
  type        = string
  description = "MetalLB version to install in the local cluster."
  default     = "v0.14.9"
}

variable "metallb_ip_range" {
  type        = string
  description = "Optional explicit MetalLB address range in start-end form. When empty, the range is derived from the k3d Docker network."
  default     = ""
}
