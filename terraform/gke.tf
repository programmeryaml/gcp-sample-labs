# ── GKE Cluster ────────────────────────────────────────────────────────────
resource "google_container_cluster" "nexus_cluster" {
  name     = var.cluster_name
  location = var.zone

  # Remove the default node pool after cluster creation so we can
  # manage our own node pool below.
  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled = false
  }
}

# ── Node Pool: 1 × n1-standard-1 preemptible VM ────────────────────────────
resource "google_container_node_pool" "nexus_nodes" {
  name       = "${var.cluster_name}-node-pool"
  cluster    = google_container_cluster.nexus_cluster.id
  location   = var.zone
  node_count = 1

  node_config {
    machine_type = "n1-standard-1"
    preemptible  = true
    disk_size_gb = 50
    disk_type    = "pd-standard"

    # Enable Workload Identity on the node pool
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = "nexus"
    }

    tags = ["nexus-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
