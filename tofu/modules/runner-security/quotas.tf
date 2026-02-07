# Runner Security Module - Resource Quotas and Limits

# =============================================================================
# ResourceQuota: cluster-appropriate limits
# =============================================================================

resource "kubernetes_resource_quota_v1" "runners" {
  metadata {
    name      = "runner-quota"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    hard = {
      "requests.cpu"    = var.quota_cpu_requests
      "requests.memory" = var.quota_memory_requests
      "pods"            = var.quota_max_pods
    }
  }
}

# =============================================================================
# LimitRange: sane defaults for job pods without explicit limits
# =============================================================================

resource "kubernetes_limit_range_v1" "runners" {
  metadata {
    name      = "runner-limits"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.limit_default_cpu
        memory = var.limit_default_memory
      }

      default_request = {
        cpu    = var.limit_default_cpu_request
        memory = var.limit_default_memory_request
      }

      max = {
        cpu    = var.limit_max_cpu
        memory = var.limit_max_memory
      }
    }
  }
}
