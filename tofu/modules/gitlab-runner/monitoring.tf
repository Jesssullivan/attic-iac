# GitLab Runner Module - Monitoring Configuration
#
# Prometheus ServiceMonitor for runner metrics collection.

# =============================================================================
# Prometheus ServiceMonitor
# =============================================================================

resource "kubernetes_manifest" "service_monitor" {
  count = var.service_monitor_enabled ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"

    metadata = {
      name      = "${var.runner_name}-monitor"
      namespace = var.namespace
      labels = merge(local.common_labels, var.service_monitor_labels, {
        "app.kubernetes.io/component" = "monitoring"
      })
    }

    spec = {
      selector = {
        matchLabels = {
          "app"     = var.runner_name
          "release" = var.runner_name
        }
      }

      endpoints = [
        {
          port     = "metrics"
          interval = "30s"
          path     = "/metrics"

          relabelings = [
            {
              sourceLabels = ["__meta_kubernetes_pod_label_app"]
              targetLabel  = "app"
            },
            {
              sourceLabels = ["__meta_kubernetes_pod_label_release"]
              targetLabel  = "runner"
            },
            {
              sourceLabels = ["__meta_kubernetes_namespace"]
              targetLabel  = "namespace"
            }
          ]

          metricRelabelings = [
            {
              sourceLabels = ["__name__"]
              regex        = "gitlab_runner_.*"
              action       = "keep"
            }
          ]
        }
      ]

      namespaceSelector = {
        matchNames = [var.namespace]
      }
    }
  }

  depends_on = [helm_release.gitlab_runner]
}

# =============================================================================
# PrometheusRule for Alerts (Optional)
# =============================================================================

resource "kubernetes_manifest" "prometheus_rules" {
  count = var.service_monitor_enabled ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"

    metadata = {
      name      = "${var.runner_name}-alerts"
      namespace = var.namespace
      labels = merge(local.common_labels, var.service_monitor_labels, {
        "app.kubernetes.io/component" = "alerting"
      })
    }

    spec = {
      groups = [
        {
          name = "gitlab-runner-${var.runner_name}"

          rules = [
            {
              alert = "GitLabRunnerDown"
              expr  = "up{job=\"${var.runner_name}\"} == 0"
              for   = "5m"
              labels = {
                severity = "critical"
                runner   = var.runner_name
              }
              annotations = {
                summary     = "GitLab Runner {{ $labels.runner }} is down"
                description = "GitLab Runner {{ $labels.runner }} in namespace {{ $labels.namespace }} has been down for more than 5 minutes."
              }
            },
            {
              alert = "GitLabRunnerHighJobFailureRate"
              expr  = "rate(gitlab_runner_failed_jobs_total{runner=\"${var.runner_name}\"}[15m]) / rate(gitlab_runner_jobs_total{runner=\"${var.runner_name}\"}[15m]) > 0.1"
              for   = "15m"
              labels = {
                severity = "warning"
                runner   = var.runner_name
              }
              annotations = {
                summary     = "GitLab Runner {{ $labels.runner }} has high job failure rate"
                description = "GitLab Runner {{ $labels.runner }} has a job failure rate above 10% for the last 15 minutes."
              }
            },
            {
              alert = "GitLabRunnerNoJobsProcessed"
              expr  = "increase(gitlab_runner_jobs_total{runner=\"${var.runner_name}\"}[1h]) == 0"
              for   = "2h"
              labels = {
                severity = "warning"
                runner   = var.runner_name
              }
              annotations = {
                summary     = "GitLab Runner {{ $labels.runner }} not processing jobs"
                description = "GitLab Runner {{ $labels.runner }} has not processed any jobs in the last 2 hours."
              }
            },
            {
              alert = "GitLabRunnerHighCPU"
              expr  = "rate(container_cpu_usage_seconds_total{pod=~\"${var.runner_name}-.*\"}[5m]) > 0.8"
              for   = "10m"
              labels = {
                severity = "warning"
                runner   = var.runner_name
              }
              annotations = {
                summary     = "GitLab Runner {{ $labels.runner }} high CPU usage"
                description = "GitLab Runner {{ $labels.runner }} is using more than 80% CPU for the last 10 minutes."
              }
            },
            {
              alert = "GitLabRunnerHighMemory"
              expr  = "container_memory_usage_bytes{pod=~\"${var.runner_name}-.*\"} / container_spec_memory_limit_bytes{pod=~\"${var.runner_name}-.*\"} > 0.85"
              for   = "10m"
              labels = {
                severity = "warning"
                runner   = var.runner_name
              }
              annotations = {
                summary     = "GitLab Runner {{ $labels.runner }} high memory usage"
                description = "GitLab Runner {{ $labels.runner }} is using more than 85% of its memory limit for the last 10 minutes."
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.gitlab_runner]
}
