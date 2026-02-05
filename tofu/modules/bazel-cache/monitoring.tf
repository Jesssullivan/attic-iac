# bazel-cache Module - Prometheus Monitoring

# =============================================================================
# ServiceMonitor
# =============================================================================

resource "kubectl_manifest" "service_monitor" {
  count = var.enable_metrics && var.create_service_monitor ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.name}-metrics"
      namespace = var.namespace
      labels = merge(local.labels, {
        "prometheus" = var.prometheus_release_label
      })
    }
    spec = {
      selector = {
        matchLabels = local.selector_labels
      }
      endpoints = [
        {
          port     = "http"
          interval = "30s"
          path     = "/metrics"
        }
      ]
      namespaceSelector = {
        matchNames = [var.namespace]
      }
    }
  })
}

# =============================================================================
# PrometheusRule for Alerts
# =============================================================================

resource "kubectl_manifest" "prometheus_rules" {
  count = var.enable_metrics && var.create_service_monitor ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "${var.name}-alerts"
      namespace = var.namespace
      labels = merge(local.labels, {
        "prometheus" = var.prometheus_release_label
      })
    }
    spec = {
      groups = [
        {
          name = "${var.name}.rules"
          rules = [
            {
              alert = "BazelCacheDown"
              expr  = "up{job=\"${var.name}\"} == 0"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "Bazel cache ${var.name} is down"
                description = "Bazel cache ${var.name} in namespace ${var.namespace} has been unreachable for more than 5 minutes."
              }
            },
            {
              alert = "BazelCacheHighLatency"
              expr  = "histogram_quantile(0.95, rate(bazel_remote_http_request_duration_seconds_bucket{job=\"${var.name}\"}[5m])) > 1"
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Bazel cache p95 latency is high"
                description = "Bazel cache ${var.name} has p95 latency > 1s for more than 10 minutes."
              }
            },
            {
              alert = "BazelCacheHighErrorRate"
              expr  = "rate(bazel_remote_http_request_total{job=\"${var.name}\",code=~\"5..\"}[5m]) / rate(bazel_remote_http_request_total{job=\"${var.name}\"}[5m]) > 0.05"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Bazel cache error rate is high"
                description = "Bazel cache ${var.name} has error rate > 5% for more than 5 minutes."
              }
            },
            {
              alert = "BazelCacheS3Errors"
              expr  = "rate(bazel_remote_s3_requests_total{job=\"${var.name}\",status=\"error\"}[5m]) > 1"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Bazel cache S3 backend errors"
                description = "Bazel cache ${var.name} has S3 backend errors for more than 5 minutes."
              }
            }
          ]
        }
      ]
    }
  })
}
