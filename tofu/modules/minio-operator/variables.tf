# MinIO Operator Module - Variables
#
# Configuration variables for the MinIO operator Helm installation.

# =============================================================================
# Installation Control
# =============================================================================

variable "install_operator" {
  description = "Whether to install the MinIO operator"
  type        = bool
  default     = true
}

variable "create_namespace" {
  description = "Create the namespace for the operator"
  type        = bool
  default     = true
}

# =============================================================================
# Namespace & Release
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for MinIO operator"
  type        = string
  default     = "minio-operator"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "minio-operator"
}

# =============================================================================
# Helm Chart Configuration
# =============================================================================

variable "operator_version" {
  description = "MinIO operator Helm chart version"
  type        = string
  default     = "6.0.4"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600
}

# =============================================================================
# Operator Configuration
# =============================================================================

variable "operator_replicas" {
  description = "Number of operator replicas"
  type        = number
  default     = 1
}

variable "enable_console" {
  description = "Enable MinIO Console (web UI). Disabled by default to reduce resource usage."
  type        = bool
  default     = false
}

# =============================================================================
# Resource Limits
# =============================================================================

variable "operator_cpu_request" {
  description = "CPU request for operator pods"
  type        = string
  default     = "50m"
}

variable "operator_cpu_limit" {
  description = "CPU limit for operator pods"
  type        = string
  default     = "500m"
}

variable "operator_memory_request" {
  description = "Memory request for operator pods"
  type        = string
  default     = "64Mi"
}

variable "operator_memory_limit" {
  description = "Memory limit for operator pods"
  type        = string
  default     = "256Mi"
}
