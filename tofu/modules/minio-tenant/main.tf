# MinIO Tenant Module
#
# Creates a MinIO Tenant CRD resource for S3-compatible object storage.
# Supports both standalone (single server) and distributed (multi-server) modes.
#
# This module is optimized for Nix binary cache workloads.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# =============================================================================
# Locals
# =============================================================================

locals {
  tenant_labels = merge(
    {
      "app.kubernetes.io/name"       = "minio"
      "app.kubernetes.io/instance"   = var.tenant_name
      "app.kubernetes.io/component"  = "storage"
      "app.kubernetes.io/part-of"    = "attic-cache"
      "app.kubernetes.io/managed-by" = "opentofu"
    },
    var.additional_labels
  )

  # Headless service name for internal communication
  headless_service = "${var.tenant_name}-hl"

  # S3 endpoint for internal cluster access
  s3_endpoint = "http://${local.headless_service}.${var.namespace}.svc:9000"
}

# =============================================================================
# MinIO Tenant CRD
# =============================================================================

resource "kubectl_manifest" "minio_tenant" {
  yaml_body = yamlencode({
    apiVersion = "minio.min.io/v2"
    kind       = "Tenant"
    metadata = {
      name      = var.tenant_name
      namespace = var.namespace
      labels    = local.tenant_labels
    }
    spec = {
      # Image configuration
      image           = var.minio_image
      imagePullPolicy = "IfNotPresent"

      # Pool configuration
      pools = var.distributed_mode ? [
        # Distributed mode: 4 servers × 4 drives = 16 drives total
        # Provides erasure coding and high availability
        {
          name             = "pool-0"
          servers          = 4
          volumesPerServer = 4
          volumeClaimTemplate = {
            metadata = {
              labels = local.tenant_labels
            }
            spec = {
              storageClassName = var.storage_class
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.volume_size
                }
              }
            }
          }
          resources = {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 1000
            runAsGroup   = 1000
            fsGroup      = 1000
          }
        }
        ] : [
        # Standalone mode: 1 server × 1 drive
        # Suitable for development and testing
        {
          name             = "pool-0"
          servers          = 1
          volumesPerServer = 1
          volumeClaimTemplate = {
            metadata = {
              labels = local.tenant_labels
            }
            spec = {
              storageClassName = var.storage_class
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.volume_size
                }
              }
            }
          }
          resources = {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }
          securityContext = {
            runAsNonRoot = true
            runAsUser    = 1000
            runAsGroup   = 1000
            fsGroup      = 1000
          }
        }
      ]

      # Service exposure
      exposeServices = {
        minio   = true
        console = var.enable_console
      }

      # Credentials secret reference
      configuration = {
        name = var.credentials_secret
      }

      # Environment variables for cache-optimized settings
      env = [
        {
          name  = "MINIO_API_REQUESTS_MAX"
          value = tostring(var.api_requests_max)
        },
        {
          name  = "MINIO_BROWSER"
          value = var.enable_console ? "on" : "off"
        }
      ]

      # Prometheus monitoring
      prometheusOperator = var.enable_monitoring

      # Request auto-certificate from cert-manager (if enabled)
      requestAutoCert = var.request_auto_cert

      # Bucket configuration
      buckets = [
        for bucket in var.buckets : {
          name       = bucket.name
          objectLock = lookup(bucket, "object_lock", false)
          region     = lookup(bucket, "region", "us-east-1")
        }
      ]

      # User configuration (optional)
      users = var.users
    }
  })

  # Force replacement if major config changes
  force_conflicts   = true
  server_side_apply = true
}

# =============================================================================
# Wait for MinIO to be Ready
# =============================================================================

resource "null_resource" "wait_for_tenant" {
  depends_on = [kubectl_manifest.minio_tenant]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for MinIO tenant ${var.tenant_name} to be ready..."
      for i in $(seq 1 60); do
        STATUS=$(kubectl get tenant ${var.tenant_name} -n ${var.namespace} -o jsonpath='{.status.currentState}' 2>/dev/null || echo "Unknown")
        if [ "$STATUS" = "Initialized" ]; then
          echo "MinIO tenant is ready (Initialized)"
          exit 0
        fi
        echo "Attempt $i: Status=$STATUS, waiting..."
        sleep 5
      done
      echo "WARNING: Timeout waiting for MinIO tenant to be ready"
      exit 0
    EOT
  }
}
