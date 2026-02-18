# GitLab Runner Module - Horizontal Pod Autoscaler
#
# Configures HPA for runner manager pods based on CPU and memory utilization.

# =============================================================================
# Horizontal Pod Autoscaler
# =============================================================================

resource "kubernetes_horizontal_pod_autoscaler_v2" "runner" {
  count = var.hpa_enabled ? 1 : 0

  metadata {
    name      = "${var.runner_name}-hpa"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = var.runner_name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    # CPU-based scaling
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_target
        }
      }
    }

    # Memory-based scaling
    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_target
        }
      }
    }

    # Scaling behavior
    behavior {
      # Scale up quickly to handle job bursts
      scale_up {
        stabilization_window_seconds = var.hpa_scale_up_window

        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 30
        }

        policy {
          type           = "Pods"
          value          = 2
          period_seconds = 30
        }

        select_policy = "Max"
      }

      # Scale down slowly to avoid disrupting running jobs
      scale_down {
        stabilization_window_seconds = var.hpa_scale_down_window

        policy {
          type           = "Percent"
          value          = 30
          period_seconds = 60
        }

        select_policy = "Min"
      }
    }
  }

  depends_on = [helm_release.gitlab_runner]
}

# =============================================================================
# Pod Disruption Budget
# =============================================================================

resource "kubernetes_pod_disruption_budget_v1" "runner" {
  count = var.pdb_enabled ? 1 : 0

  metadata {
    name      = "${var.runner_name}-pdb"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    min_available = var.pdb_min_available

    selector {
      match_labels = {
        "app"     = var.runner_name
        "release" = var.runner_name
      }
    }
  }

  depends_on = [helm_release.gitlab_runner]
}
