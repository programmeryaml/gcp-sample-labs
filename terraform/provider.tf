terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure to store state in GCS:
  backend "gcs" {
    bucket = "gcs-cm-tf-state"
    prefix = "terraform/nexus"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
