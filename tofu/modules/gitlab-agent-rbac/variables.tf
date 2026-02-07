# GitLab Agent RBAC Module - Variables

variable "namespace" {
  description = "Kubernetes namespace for RBAC resources"
  type        = string
}

variable "allowed_verbs" {
  description = "Allowed verbs for CI job access"
  type        = list(string)
  default     = ["get", "list", "watch"]
}
