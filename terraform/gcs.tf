# ── GCS Bucket for Nexus artifacts ─────────────────────────────────────────
resource "google_storage_bucket" "nexus_artifacts" {
  name          = "${var.project_id}-${var.gcs_bucket_name}"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  dynamic "lifecycle_rule" {
    for_each = var.artifact_retention_days > 0 ? [1] : []
    content {
      condition {
        age = var.artifact_retention_days
      }
      action {
        type = "Delete"
      }
    }
  }
}

# ── Service Account for Nexus (used via Workload Identity) ─────────────────
resource "google_service_account" "nexus_sa" {
  account_id   = var.nexus_sa_name
  display_name = "Nexus Repository Manager Service Account"
  project      = var.project_id
}

# Grant the SA read/write access to the artifact bucket
resource "google_storage_bucket_iam_member" "nexus_sa_bucket_access" {
  bucket = google_storage_bucket.nexus_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.nexus_sa.email}"
}

# ── Workload Identity binding ───────────────────────────────────────────────
# Allows the Kubernetes service account to impersonate the GCP SA
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.nexus_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_sa_name}]"
}
