variable "cluster_name" {
  type        = string
  description = "Name of the local k3d cluster."
}

variable "namespaces" {
  type        = list(string)
  description = "Namespaces to create in the local cluster."
}

variable "app_namespaces" {
  type        = list(string)
  description = "Application namespaces that should receive quotas and defaults."
}

variable "base_domain" {
  type        = string
  description = "Base domain used for local ingress hostnames."
}

variable "argocd_host" {
  type        = string
  description = "Hostname used to reach the Argo CD UI through ingress."
}

variable "argocd_tls_secret_name" {
  type        = string
  description = "TLS secret name used by the Argo CD ingress."
}
