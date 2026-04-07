output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.nexus_cluster.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.nexus_cluster.endpoint
  sensitive   = true
}

output "gcs_bucket_name" {
  description = "GCS bucket used for Nexus blob store"
  value       = google_storage_bucket.nexus_artifacts.name
}

output "nexus_service_account_email" {
  description = "GCP service account email for Nexus (use for Workload Identity annotation)"
  value       = google_service_account.nexus_sa.email
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for the new cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.nexus_cluster.name} --zone ${var.zone} --project ${var.project_id}"
}
