variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "project-879aa197-f3bf-471f-bd5"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the GKE node pool"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "nexus-cluster"
}

variable "gcs_bucket_name" {
  description = "Name of the GCS bucket used as the Nexus blob store"
  type        = string
  default     = "nexus-artifacts"
}

variable "nexus_sa_name" {
  description = "Name of the GCP service account used by Nexus"
  type        = string
  default     = "nexus-sa"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace where Nexus is deployed"
  type        = string
  default     = "nexus"
}

variable "kubernetes_sa_name" {
  description = "Kubernetes service account name used by the Nexus pod"
  type        = string
  default     = "nexus"
}

variable "artifact_retention_days" {
  description = "Number of days after which unused GCS objects are deleted. Set to 0 to disable lifecycle deletion."
  type        = number
  default     = 0
}
