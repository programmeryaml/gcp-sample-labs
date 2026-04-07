# Nexus on GKE

Deploy Sonatype Nexus Repository OSS on GKE with a persistent volume.

## Structure

```
docker/       README explaining why the custom GCS image was removed
kustomize/    Kubernetes manifests (base + production overlay)
terraform/    GCS bucket, GKE cluster, and IAM setup
```

## Prerequisites

- GKE cluster provisioned via Terraform
- Workload Identity Federation configured
- GitHub Actions secrets set

| Secret | Description |
|---|---|
| `GCP_PROJECT_ID` | GCP project ID |
| `GKE_CLUSTER_NAME` | GKE cluster name |
| `GKE_ZONE` | Cluster zone (e.g. `us-central1-a`) |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Federation provider resource name |
| `GCP_SERVICE_ACCOUNT` | Service account email used by the pipeline |

## Provision infrastructure

```bash
cd terraform
terraform init
terraform plan -var="project_id=${PROJECT_ID}"
terraform apply -var="project_id=${PROJECT_ID}"
```

## Deploy

Trigger the `Deploy to GKE` workflow via `workflow_dispatch` in GitHub Actions.

The pipeline:
1. Patches the Workload Identity annotation with the real GCP project ID
2. Applies the kustomize production overlay (`kubectl apply -k`)
3. Waits for the rollout to complete (300 s timeout)

## Future improvements

- ArgoCD – auto-sync `kustomize/` changes instead of running `kubectl apply` by hand
- Atlantis – run `terraform plan/apply` from PRs so infra changes go through review
- External Secrets Operator – pull secrets from Secret Manager instead of storing them in manifests
- Prometheus + Grafana – monitor pod health and Nexus JVM metrics

