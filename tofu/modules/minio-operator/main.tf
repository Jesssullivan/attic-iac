# MinIO Operator Module
#
# Installs the MinIO Operator via Helm chart.
# The operator manages MinIO Tenant CRDs for S3-compatible object storage.
#
# This module follows the same pattern as the CNPG operator module.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# =============================================================================
# Namespace
# =============================================================================

resource "kubernetes_namespace" "minio_operator" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "minio-operator"
      "app.kubernetes.io/component"  = "operator"
      "app.kubernetes.io/managed-by" = "opentofu"
    }
  }
}

# =============================================================================
# MinIO Operator Helm Release
# =============================================================================

resource "helm_release" "minio_operator" {
  count = var.install_operator ? 1 : 0

  name             = var.release_name
  repository       = "https://operator.min.io"
  chart            = "operator"
  version          = var.operator_version
  namespace        = var.namespace
  create_namespace = !var.create_namespace # Only create if we didn't already

  # Wait for deployment to be ready
  wait    = true
  timeout = var.helm_timeout

  # Operator configuration
  values = [
    yamlencode({
      operator = {
        replicaCount = var.operator_replicas
        resources = {
          requests = {
            cpu    = var.operator_cpu_request
            memory = var.operator_memory_request
          }
          limits = {
            cpu    = var.operator_cpu_limit
            memory = var.operator_memory_limit
          }
        }
        # Security context for operator pods
        securityContext = {
          runAsNonRoot = true
          runAsUser    = 1000
          fsGroup      = 1000
        }
      }
      # Disable the MinIO console (use kubectl or mc client instead)
      console = {
        enabled = var.enable_console
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.minio_operator
  ]
}

# =============================================================================
# Wait for Operator CRDs
# =============================================================================

# This null_resource ensures the Tenant CRD is available before continuing
resource "null_resource" "wait_for_crd" {
  count = var.install_operator ? 1 : 0

  depends_on = [helm_release.minio_operator]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for MinIO Tenant CRD to be available..."
      for i in $(seq 1 30); do
        if kubectl get crd tenants.minio.min.io >/dev/null 2>&1; then
          echo "MinIO Tenant CRD is available"
          exit 0
        fi
        echo "Attempt $i: CRD not yet available, waiting..."
        sleep 2
      done
      echo "WARNING: Timeout waiting for MinIO Tenant CRD"
      exit 0
    EOT
  }
}
