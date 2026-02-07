# Bates ILS Runners Stack - Variables

# =============================================================================
# Kubernetes Authentication
# =============================================================================

variable "k8s_config_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = ""
}

variable "cluster_context" {
  description = "Kubernetes context for GitLab Agent"
  type        = string
}

# =============================================================================
# GitLab Configuration
# =============================================================================

variable "gitlab_url" {
  description = "GitLab instance URL"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_token" {
  description = "GitLab API token with create_runner scope (for automated token lifecycle)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gitlab_group_id" {
  description = "GitLab group ID for automated runner registration (0 = use manual tokens)"
  type        = number
  default     = 0
}

# =============================================================================
# Namespace
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for runners"
  type        = string
  default     = "bates-ils-runners"
}

# =============================================================================
# Runner Deployment Toggles
# =============================================================================

variable "deploy_docker_runner" {
  description = "Deploy the docker runner"
  type        = bool
  default     = true
}

variable "deploy_dind_runner" {
  description = "Deploy the dind runner"
  type        = bool
  default     = true
}

variable "deploy_rocky8_runner" {
  description = "Deploy the Rocky 8 runner"
  type        = bool
  default     = true
}

variable "deploy_rocky9_runner" {
  description = "Deploy the Rocky 9 runner"
  type        = bool
  default     = true
}

variable "deploy_nix_runner" {
  description = "Deploy the Nix runner"
  type        = bool
  default     = true
}

# =============================================================================
# Runner Tokens (Sensitive)
# =============================================================================

variable "docker_runner_token" {
  description = "Runner token for docker runner"
  type        = string
  sensitive   = true
  default     = ""
}

variable "dind_runner_token" {
  description = "Runner token for dind runner"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rocky8_runner_token" {
  description = "Runner token for Rocky 8 runner"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rocky9_runner_token" {
  description = "Runner token for Rocky 9 runner"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nix_runner_token" {
  description = "Runner token for Nix runner"
  type        = string
  sensitive   = true
  default     = ""
}

# =============================================================================
# Runner Tags (Customization)
# =============================================================================

variable "docker_runner_tags" {
  description = "Additional tags for docker runner"
  type        = list(string)
  default     = []
}

variable "dind_runner_tags" {
  description = "Additional tags for dind runner"
  type        = list(string)
  default     = []
}

variable "rocky8_runner_tags" {
  description = "Additional tags for Rocky 8 runner"
  type        = list(string)
  default     = []
}

variable "rocky9_runner_tags" {
  description = "Additional tags for Rocky 9 runner"
  type        = list(string)
  default     = []
}

variable "nix_runner_tags" {
  description = "Additional tags for Nix runner"
  type        = list(string)
  default     = []
}

# =============================================================================
# Concurrency Settings
# =============================================================================

variable "docker_concurrent_jobs" {
  description = "Max concurrent jobs for docker runner"
  type        = number
  default     = 8
}

variable "dind_concurrent_jobs" {
  description = "Max concurrent jobs for dind runner"
  type        = number
  default     = 4
}

variable "rocky8_concurrent_jobs" {
  description = "Max concurrent jobs for Rocky 8 runner"
  type        = number
  default     = 4
}

variable "rocky9_concurrent_jobs" {
  description = "Max concurrent jobs for Rocky 9 runner"
  type        = number
  default     = 4
}

variable "nix_concurrent_jobs" {
  description = "Max concurrent jobs for Nix runner"
  type        = number
  default     = 4
}

# =============================================================================
# Manager Pod Resources - Docker
# =============================================================================

variable "docker_cpu_request" {
  description = "CPU request for docker runner manager"
  type        = string
  default     = "100m"
}

variable "docker_memory_request" {
  description = "Memory request for docker runner manager"
  type        = string
  default     = "128Mi"
}

variable "docker_cpu_limit" {
  description = "CPU limit for docker runner manager"
  type        = string
  default     = "500m"
}

variable "docker_memory_limit" {
  description = "Memory limit for docker runner manager"
  type        = string
  default     = "512Mi"
}

# =============================================================================
# Manager Pod Resources - DinD
# =============================================================================

variable "dind_cpu_request" {
  description = "CPU request for dind runner manager"
  type        = string
  default     = "200m"
}

variable "dind_memory_request" {
  description = "Memory request for dind runner manager"
  type        = string
  default     = "256Mi"
}

variable "dind_cpu_limit" {
  description = "CPU limit for dind runner manager"
  type        = string
  default     = "1"
}

variable "dind_memory_limit" {
  description = "Memory limit for dind runner manager"
  type        = string
  default     = "1Gi"
}

# =============================================================================
# Manager Pod Resources - Rocky (shared by 8 and 9)
# =============================================================================

variable "rocky_cpu_request" {
  description = "CPU request for Rocky runner managers"
  type        = string
  default     = "100m"
}

variable "rocky_memory_request" {
  description = "Memory request for Rocky runner managers"
  type        = string
  default     = "128Mi"
}

variable "rocky_cpu_limit" {
  description = "CPU limit for Rocky runner managers"
  type        = string
  default     = "500m"
}

variable "rocky_memory_limit" {
  description = "Memory limit for Rocky runner managers"
  type        = string
  default     = "512Mi"
}

# =============================================================================
# Manager Pod Resources - Nix
# =============================================================================

variable "nix_cpu_request" {
  description = "CPU request for Nix runner manager"
  type        = string
  default     = "100m"
}

variable "nix_memory_request" {
  description = "Memory request for Nix runner manager"
  type        = string
  default     = "128Mi"
}

variable "nix_cpu_limit" {
  description = "CPU limit for Nix runner manager"
  type        = string
  default     = "500m"
}

variable "nix_memory_limit" {
  description = "Memory limit for Nix runner manager"
  type        = string
  default     = "512Mi"
}

# =============================================================================
# Job Pod Resources - Docker
# =============================================================================

variable "docker_job_cpu_request" {
  description = "CPU request for docker job pods"
  type        = string
  default     = "100m"
}

variable "docker_job_memory_request" {
  description = "Memory request for docker job pods"
  type        = string
  default     = "256Mi"
}

variable "docker_job_cpu_limit" {
  description = "CPU limit for docker job pods"
  type        = string
  default     = "2"
}

variable "docker_job_memory_limit" {
  description = "Memory limit for docker job pods"
  type        = string
  default     = "2Gi"
}

# =============================================================================
# Job Pod Resources - DinD
# =============================================================================

variable "dind_job_cpu_request" {
  description = "CPU request for dind job pods"
  type        = string
  default     = "500m"
}

variable "dind_job_memory_request" {
  description = "Memory request for dind job pods"
  type        = string
  default     = "1Gi"
}

variable "dind_job_cpu_limit" {
  description = "CPU limit for dind job pods"
  type        = string
  default     = "4"
}

variable "dind_job_memory_limit" {
  description = "Memory limit for dind job pods"
  type        = string
  default     = "8Gi"
}

# =============================================================================
# Job Pod Resources - Rocky (shared by 8 and 9)
# =============================================================================

variable "rocky_job_cpu_request" {
  description = "CPU request for Rocky job pods"
  type        = string
  default     = "100m"
}

variable "rocky_job_memory_request" {
  description = "Memory request for Rocky job pods"
  type        = string
  default     = "256Mi"
}

variable "rocky_job_cpu_limit" {
  description = "CPU limit for Rocky job pods"
  type        = string
  default     = "2"
}

variable "rocky_job_memory_limit" {
  description = "Memory limit for Rocky job pods"
  type        = string
  default     = "2Gi"
}

# =============================================================================
# Job Pod Resources - Nix
# =============================================================================

variable "nix_job_cpu_request" {
  description = "CPU request for Nix job pods"
  type        = string
  default     = "500m"
}

variable "nix_job_memory_request" {
  description = "Memory request for Nix job pods"
  type        = string
  default     = "1Gi"
}

variable "nix_job_cpu_limit" {
  description = "CPU limit for Nix job pods"
  type        = string
  default     = "4"
}

variable "nix_job_memory_limit" {
  description = "Memory limit for Nix job pods"
  type        = string
  default     = "8Gi"
}

# =============================================================================
# DinD Configuration
# =============================================================================

variable "docker_version" {
  description = "Docker version for DinD service"
  type        = string
  default     = "27-dind"
}

variable "dind_node_selector" {
  description = "Node selector for DinD runner (privileged workloads)"
  type        = map(string)
  default     = {}
}

variable "dind_tolerations" {
  description = "Tolerations for DinD runner"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

# =============================================================================
# Nix/Attic Configuration
# =============================================================================

variable "attic_server" {
  description = "Attic cache server URL"
  type        = string
  default     = ""
}

variable "attic_cache" {
  description = "Attic cache name"
  type        = string
  default     = "main"
}

variable "attic_token" {
  description = "Attic authentication token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "nix_store_size" {
  description = "Size limit for Nix store emptyDir volume"
  type        = string
  default     = "20Gi"
}

# =============================================================================
# HPA Configuration
# =============================================================================

variable "hpa_enabled" {
  description = "Enable Horizontal Pod Autoscaler for all runners"
  type        = bool
  default     = true
}

variable "hpa_cpu_target" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 70
}

variable "hpa_memory_target" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80
}

variable "hpa_scale_up_window" {
  description = "Stabilization window for scaling up (seconds)"
  type        = number
  default     = 15
}

variable "hpa_scale_down_window" {
  description = "Stabilization window for scaling down (seconds)"
  type        = number
  default     = 300
}

# Per-runner HPA min/max replicas

variable "docker_hpa_min_replicas" {
  description = "Min replicas for docker runner"
  type        = number
  default     = 1
}

variable "docker_hpa_max_replicas" {
  description = "Max replicas for docker runner"
  type        = number
  default     = 5
}

variable "dind_hpa_min_replicas" {
  description = "Min replicas for dind runner"
  type        = number
  default     = 1
}

variable "dind_hpa_max_replicas" {
  description = "Max replicas for dind runner"
  type        = number
  default     = 3
}

variable "rocky_hpa_min_replicas" {
  description = "Min replicas for Rocky runners"
  type        = number
  default     = 1
}

variable "rocky_hpa_max_replicas" {
  description = "Max replicas for Rocky runners"
  type        = number
  default     = 3
}

variable "nix_hpa_min_replicas" {
  description = "Min replicas for Nix runner"
  type        = number
  default     = 1
}

variable "nix_hpa_max_replicas" {
  description = "Max replicas for Nix runner"
  type        = number
  default     = 3
}

# =============================================================================
# Pod Disruption Budget
# =============================================================================

variable "pdb_enabled" {
  description = "Enable Pod Disruption Budget for all runners"
  type        = bool
  default     = true
}

# =============================================================================
# Monitoring Configuration
# =============================================================================

variable "metrics_enabled" {
  description = "Enable Prometheus metrics endpoint"
  type        = bool
  default     = true
}

variable "service_monitor_enabled" {
  description = "Create Prometheus ServiceMonitor resources"
  type        = bool
  default     = false
}

variable "service_monitor_labels" {
  description = "Labels for ServiceMonitor resources"
  type        = map(string)
  default = {
    "prometheus" = "kube-prometheus"
  }
}
