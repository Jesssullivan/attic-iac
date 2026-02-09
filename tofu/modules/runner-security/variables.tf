# Runner Security Module - Variables

variable "namespace" {
  description = "Kubernetes namespace for security policies"
  type        = string
}

variable "quota_cpu_requests" {
  description = "Total CPU requests quota"
  type        = string
  default     = "16"
}

variable "quota_memory_requests" {
  description = "Total memory requests quota"
  type        = string
  default     = "32Gi"
}

variable "quota_max_pods" {
  description = "Maximum number of pods"
  type        = string
  default     = "50"
}

variable "limit_default_cpu" {
  description = "Default CPU limit for containers"
  type        = string
  default     = "1"
}

variable "limit_default_memory" {
  description = "Default memory limit for containers"
  type        = string
  default     = "1Gi"
}

variable "limit_default_cpu_request" {
  description = "Default CPU request for containers"
  type        = string
  default     = "100m"
}

variable "limit_default_memory_request" {
  description = "Default memory request for containers"
  type        = string
  default     = "128Mi"
}

variable "limit_max_cpu" {
  description = "Maximum CPU per container"
  type        = string
  default     = "4"
}

variable "limit_max_memory" {
  description = "Maximum memory per container"
  type        = string
  default     = "8Gi"
}

variable "priority_classes_enabled" {
  description = "Create PriorityClasses for runner manager and job pods"
  type        = bool
  default     = false
}
